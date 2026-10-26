# tms-dependency-admin

#### Dette prosjektet brukes til å definere og distribuere kotlin-dependencies for Team min-sides prosjekter 

## Access token

Dette repoet krever et github personal access-token med scopes `repo` og `workflow`. 

Dette settes som en [actions-secret](https://github.com/navikt/tms-dependency-admin/settings/secrets/actions) i variablen `API_ACCESS_TOKEN`.


## Organisering av dependencies

Definer et sett med dependencies innen samme gruppe eller område som et interface i `buildSrc/src/main/kotlin/default/dependencies.kt`

``` kotlin
interface BibliotekDefaults: DependencyGroup {
    override val groupId get() = "no.nav.bibliotek"
    override val version get() = "1.0.0"

    val dependencyEn get() = dependency("dependency-en")
    val dependencyTo get() = dependency("dependency-to")
}
```
### Ny organisering av dependencies

Den nye løsningen bruker en publisert Gradle-versjonskatalog i stedet for å kopiere buildSrc-filer til hvert prosjekt.
Dokumentasjonen for den gamle løsningen beholdes til alle prosjektene er migrert.

Felles dependencies defineres i `gradle/libs.versions.toml`, med versjoner i `[versions]` og biblioteker i `[libraries]`:

```toml
[versions]
bibliotek = "1.0.0"

[libraries]
bibliotek-en = { group = "no.nav.bibliotek", name = "dependency-en", version.ref = "bibliotek" }
bibliotek-to = { group = "no.nav.bibliotek", name = "dependency-to", version = "2.0.0" }
```

Biblioteker som brukes sammen, kan samles i bundles. Legg for eksempel dette til i samme TOML-fil:
```toml
[bundles]
bibliotek = ["bibliotek-en", "bibliotek-to"]
```

Katalogen legger ikke automatisk til dependencies i konsumentprosjektene. Hvert prosjekt velger selv
hvilke biblioteker og bundles det trenger.

### Bruk av dependencies

Importer katalogen i konsumentens `settings.gradle.kts`. Erstatt `<<name>>` med ønsket katalognavn og
`<<version>>` med en publisert versjon fra [releases](https://github.com/navikt/tms-dependency-admin/releases):
```kotlin
dependencyResolutionManagement {
    repositories {
        mavenCentral()
        maven("https://github-package-registry-mirror.gc.nav.no/cached/maven-release")
    }
    versionCatalogs {
        create("<<name>>") {
            from("no.nav.tms:tms-dependency-admin:<<version>>")
        }
    }
}
```

Katalognavnet bestemmer prefikset i `build.gradle.kts`. Hvis du velger `libs` som navn, kan du bruke
aliasene slik (bindestreker i aliaser blir til punktum i Kotlin):

```kotlin
dependencies {
    implementation(libs.jackson.moduleKotlin)
    implementation(libs.bundles.flyway)
    testImplementation(libs.mockk.default)
    testImplementation(libs.junit.api)
    testRuntimeOnly(libs.junit.engine)
    testRuntimeOnly(libs.junit.launcher)
}

tasks.test {
    useJUnitPlatform()
}
```

Bundles bruker samme syntaks, for eksempel `testImplementation(libs.bundles.kotest)`.
En bundle velger ikke konfigurasjon for hvert bibliotek: alle innslag legges til konfigurasjonen den brukes med.
Velg derfor biblioteker eller bundles som passer til `implementation`, `testImplementation` eller `testRuntimeOnly`.

### Lokale tilpasninger

Hvis prosjektet trenger egne dependencies, kan de defineres i prosjektets lokale `gradle/libs.versions.toml`.
Gradle importerer denne filen automatisk som `libs`. Gi da den felles katalogen et annet navn i
`create("<<name>>")` for å unngå navnekollisjon. Lokale dependencies brukes via `libs`, og felles dependencies
via det valgte navnet. Ikke importer den lokale filen manuelt en gang til.

For å overstyre en versjon fra `[versions]`, legg `version(...)` i katalogens eksisterende `create`-blokk
under `dependencyResolutionManagement.versionCatalogs` i konsumentprosjektets `settings.gradle.kts`.
For eksempel, for å overstyre Flyway-versjonen:

```kotlin
dependencyResolutionManagement {
    versionCatalogs {
        create("<<name>>") {
            from("no.nav.tms:tms-dependency-admin:<<version>>")
            version("flyway", "<<ønsket-flyway-versjon>>")
        }
    }
}
```

Dette erstatter katalogblokken i importeksempelet; ikke opprett samme katalog to ganger. Behold repository-oppsettet.
Overstyringen gjelder alle bibliotekene som bruker `version.ref = "flyway"`.

Det er også mulig å overstyre bare ett bibliotek ved å definere det eksisterende aliaset på nytt med en egen versjon.
Legg dette i samme `create("<<name>>")`-blokk i `settings.gradle.kts`, etter `from(...)`, i stedet for `version(...)`:

```kotlin
library("flyway-core", "org.flywaydb", "flyway-core")
    .version("<<ønsket-flyway-versjon>>")
```

Dette endrer bare aliaset `flyway-core`, ikke de andre aliasene som bruker versjonsreferansen `flyway`.
Det anbefales ikke å splitte versjonene for biblioteker som skal følge hverandre, som Flyway core og PostgreSQL-modulen.
Hold normalt alle biblioteker som deler en versjonsreferanse på samme versjon, og overstyr heller referansen samlet.
Ulike versjoner kan gi inkompatibilitet. Versjonskatalogen angir dessuten ønskede versjoner, men låser ikke resultatet
av Gradles dependency resolution.

### Distribuere dependencies

Publiseringsworkflowen for `gradle/libs.versions.toml` verifiserer først at alle bibliotekaliasene kan resolves.
Den kjører ikke tester eller bygg i konsumentprosjektene. Hvis verifiseringen feiler, publiseres ingen ny katalog.

Katalogen publiseres som `no.nav.tms:tms-dependency-admin:<<version>>` til GitHub Packages, ikke Maven Central.
Etter vellykket publisering opprettes en GitHub-release med samme versjon.
Formatet er `YYYYMMDD.<run_number>.<run_attempt>`, for eksempel `20261026.5.1`, og er ikke semantisk versjonering.
Publiseringen bruker workflowens `GITHUB_TOKEN`, ikke `API_ACCESS_TOKEN` fra den gamle distribusjonsløsningen.

Verifiseringen kjøres også for pull requests som endrer katalogfilen, i merge queue og ved manuell kjøring av
`Test-Catalog-Versioning`. Den kan kjøres lokalt med JDK 21:

```shell
./gradlew :dependency-verify:verifyVersionCatalogResolves
```

Konsumentene bruker en eksplisitt katalogversjon; en ny publisering oppdaterer dem ikke automatisk.
Med Dependabot konfigurert for Gradle i konsumentprosjektet kan nye katalogversjoner foreslås som pull requests.
Prosjektets egne bygg og tester må verifisere oppdateringen.

Deretter legger du til et `object` i `buildSrc/src/main/kotlin/groups.kt` som peker på dette.

``` kotlin
object Bibliotek: BibliotekDefaults
```

Dette objektet brukes i andre prosjekters `build.gradke.kts`-fil.

```kotlin
dependencies {
  implementation(Bibliotek.dependencyEn)
  implementation(Bibliotek.dependencyTo)
}
```

Dersom en ønsker en bestemt versjon av en distribuert dependency, eller ønsker helt andre dependencies, kan man legge
til dette i en egen fil i sin egen buildSrc.

Her er et eksempel der en overstyrer versjon, legger til en ekstra dependency innen en gruppe, og legger til en helt ny gruppe.

fil: `buildSrc/src/main/kotlin/groupsCustom.kt`
```kotlin
object Bibliotek_V2: BibliotekDefaults { 
  override val version = "2.0.0"
  
  val dependencyTre = dependency("dependency-tre")
}

object AnnetLib {
    val dependencyABC = "com.domain:abc:1.0.0"
}
```

Og brukes slik:
```kotlin
dependencies {
  implementation(Bibliotek_V2.dependencyEn)
  implementation(Bibliotek_v2.dependencyTo)
  implementation(Bibliotek_v2.dependencyTre)
  implementation(AnnetLib.dependencyABC)
}
```

## Distribusjon

Dependency-config distribueres til alle apper definert i `config/managed_apps.conf` når det gjøres endringer i
`buildSrc/src/main/kotlin/default/dependencies.kt` eller `buildSrc/src/main/kotlin/groups.kt`. Endringene plasseres på
en egen branch i mål-prosjektet, og trigger et workflow som verifiserer at endringene ikke brekker bygg, og så merger til main.

Denne workflowen vil også distribueres til de enkelte prosjektene dersom de ikke har den, eller ikke har nyeste versjon.

Dersom en ønsker å publisere dependencies til ett bestemt prosjekt kan en bruke workflow-dispatch. Dette prosjektet trenger ikke
være i `managed_apps.conf`

## Snyk

Dependencies som distribueres herfra scannes av Snyk hver dag, som finnes potensielle problemer og svakheter. 

Resultat av scan finner en på [snyk-dashboard](https://app.snyk.io/org/min-side/project/892828c4-26f8-4a18-be25-7f37aa4e9574).

# Henvendelser

Spørsmål knyttet til koden eller prosjektet kan stilles som issues her på github.

## For NAV-ansatte

Interne henvendelser kan sendes via Slack i kanalen #team-minside.

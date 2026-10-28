# tms-dependency-admin

#### Dette prosjektet brukes til å definere og distribuere kotlin-dependencies for Team min-sides prosjekter 

### Organisering av dependencies

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

Biblioteker som brukes sammen, kan samles i bundles.
```toml
[bundles]
bibliotek = ["bibliotek-en", "bibliotek-to"]
```

Katalogen legger ikke automatisk til dependencies i konsumentprosjektene. Hvert prosjekt velger selv
hvilke biblioteker og bundles det trenger.

### Bruk av dependencies

Importer katalogen i konsumentens `settings.gradle.kts`. 
`managed` er var konvensjon på katalognavn

Erstatt `<<version>>` med en publisert versjon fra [releases](https://github.com/navikt/tms-dependency-admin/releases):
```kotlin
dependencyResolutionManagement {
    repositories {
        mavenCentral()
        maven("https://github-package-registry-mirror.gc.nav.no/cached/maven-release")
    }
    versionCatalogs {
        create("managed") {
            from("no.nav.tms:tms-dependency-admin:<<version>>")
        }
    }
}
```

Bruke i build.gradle

```kotlin
dependencies {
    implementation(managed.jackson.moduleKotlin) //bibliotek
    testRuntimeOnly(managed.bundles.bibliotek) //bundle
    
}
```

### Lokale tilpasninger
* Uavhengige dependencies defineres i prosjektets lokale `gradle/libs.versions.toml`. Gradle importerer denne filen automatisk som `libs`. 

#### Utvide og overstyre versjonering fra tms-dependency-admin
Du kan endre på versjoner og legge til dependencies som skal dele versjon med andre moduler i selve versjonskatalogen i `create`-blokken  under `dependencyResolutionManagement.versionCatalogs` i ``

* For å overstyre en versjon fra `[versions]`, legg til `version(<<versionnavn fra toml fil>>, <<ønkset versjon>>)` 
* For å overstyre versjonen i ett av bibliotekene definerer du det eksisterende aliaset på nytt med en egen versjon. NB! Kun som unntak, vi vil i utgangspunktet at ting som hører sammen skal holde samme versjon
* For å legge til en modul som er del av eksisterende avhengigheter legg til `library("navn-i-build-file","<<groupId>>","<<name>>").versionRef("<<versjon definert under [version] i tomlfila >>")`

```kotlin
dependencyResolutionManagement {
    versionCatalogs {
        create("<<name>>") {
            from("no.nav.tms:tms-dependency-admin:<<version>>") 
            version("flyway", "9.0.0") //setter flyway versjonen for prosjektet til 9.0.0
            library("flyway-core", "flyway-noe-annet")
                .version("13.0.0") //overstyrer versjonen til pakkene flyway-core og flyway-noe-annet til 13.0.0
            library("jackson-databind","com.fasterxml","jackson-databind").versionRef("jacksonDatatype") // oppretter nye dependencues med versjonen av jacksonDatatype fra toml-fila
        }
    }
}
```

### Distribuere dependencies

Publiseringsworkflowen for `gradle/libs.versions.toml` verifiserer først at alle bibliotekaliasene kan resolves.
Den kjører ikke tester eller bygg i konsumentprosjektene. Hvis verifiseringen feiler, publiseres ikke katalogen.

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


# Henvendelser

Spørsmål knyttet til koden eller prosjektet kan stilles som issues her på github.

## For NAV-ansatte

Interne henvendelser kan sendes via Slack i kanalen #team-minside.

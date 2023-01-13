# tms-dependency-admin

#### Dette prosjektet brukes til å definere og distribuere kotlin-dependencies for Team min-sides prosjekter 

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

Spørsmål knyttet til koden eller prosjektet kan rettes mot https://github.com/orgs/navikt/teams/personbruker

## For NAV-ansatte

Interne henvendelser kan sendes via Slack i kanalen #team-personbruker.

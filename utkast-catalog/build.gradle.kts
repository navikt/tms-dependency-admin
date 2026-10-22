import java.net.URI

plugins {
    `version-catalog`
    `maven-publish`
}

group = "no.nav.tms"
version = providers.gradleProperty("catalogVersion").getOrElse("1.0.0")
val gitHubPackagesUrl = URI("https://maven.pkg.github.com/navikt/tms-dependency-admin")

catalog {
    versionCatalog {
        from(files("../additionalCatalogs/tms.utkast.version.toml"))
    }
}

publishing {
    publications {
        create<MavenPublication>("maven") {
            from(components["versionCatalog"])
            artifactId = "tms-utkast-catalog"
        }
    }
    repositories {
        maven {
            name = "GitHubPackages"
            url = gitHubPackagesUrl
            credentials {
                val githubUsername: String? by project
                val githubPassword: String? by project
                username = githubUsername
                password = githubPassword
            }
        }
    }
}
import com.github.benmanes.gradle.versions.updates.DependencyUpdatesTask
import java.net.URI

plugins {
    kotlin("jvm").version(libs.versions.kotlin)
    `version-catalog`
    `kotlin-dsl`
    `maven-publish`
}

group = "no.nav.tms"
version = providers.gradleProperty("catalogVersion").getOrElse("1.0.0")
val gitHubPackagesUrl = URI("https://maven.pkg.github.com/navikt/tms-dependency-admin")

catalog {
    versionCatalog {
        from(files("./gradle/libs.versions.toml"))
    }
}

repositories {
    mavenCentral()
}

kotlin {
    jvmToolchain {
        languageVersion.set(JavaLanguageVersion.of(21))
    }
    jvmToolchain(21)
}

publishing {
    publications {
        create<MavenPublication>("maven") {
            from(components["versionCatalog"])
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

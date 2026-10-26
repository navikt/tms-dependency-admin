plugins {
    base
    alias(libs.plugins.kotlin)
}

repositories {
    mavenCentral()
    maven("https://github-package-registry-mirror.gc.nav.no/cached/maven-release")
}

val catalogs = rootProject.extensions.getByType<VersionCatalogsExtension>()
val catalogToVerify = providers.gradleProperty("catalogToVerify")

tasks.register("verifyVersionCatalogResolves") {
    description = "Test that all dependencies in the version catalog resolves"
    doLast {
        val selectedCatalogs = catalogToVerify.orNull?.let { listOf(catalogs.named(it)) }
            ?: catalogs.toList()
        val failures = selectedCatalogs.flatMap { catalog ->
            catalog.libraryAliases.mapNotNull { alias ->
                val dependency = catalog.findLibrary(alias).get().get()

                try {
                    configurations.detachedConfiguration(
                        dependencies.create(dependency)
                    ).resolve()
                    null
                } catch (e: ResolveException) {
                    "${catalog.name}.$alias: ${dependency.name}: ${e.message}"
                }
            }
        }

        check(failures.isEmpty()) {
            "Dependencies failed to resolve:\n${failures.joinToString("\n")}\n"
        }

        println("All dependencies resolved successfully")
    }
}
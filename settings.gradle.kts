rootProject.name = "tms-dependency-admin"

include("dependency-verify")
include("utkast-catalog")

dependencyResolutionManagement {
    versionCatalogs {
        create("utkast") {
            from(files("additionalCatalogs/tms.utkast.versions.toml"))
        }
    }
}
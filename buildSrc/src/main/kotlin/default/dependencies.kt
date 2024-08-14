package default

// Managed by tms-dependency-admin. Overrides and additions should be placed in separate file

interface DependencyGroup {
    val groupId: String? get() = null
    val version: String? get() = null

    fun dependency(name: String, groupId: String? = this.groupId, version: String? = this.version): String {
        requireNotNull(groupId)
        requireNotNull(version)

        return "$groupId:$name:$version"
    }
}

interface FlywayDefaults: DependencyGroup {
    override val groupId get() = "org.flywaydb"
    override val version get() = "10.17.0"

    val pluginId get() = "org.flywaydb.flyway"
    val core get() = dependency("flyway-core")
    val postgres get() = dependency("flyway-database-postgresql")
}

interface HikariDefaults: DependencyGroup {
    override val groupId get() = "com.zaxxer"
    override val version get() = "5.1.0"

    val cp get() = dependency("HikariCP")
}

interface JacksonDatatypeDefaults: DependencyGroup {
    override val version get() = "2.17.2"

    val datatypeJsr310 get() = dependency("jackson-datatype-jsr310", groupId = "com.fasterxml.jackson.datatype")
    val moduleKotlin get() = dependency("jackson-module-kotlin", groupId = "com.fasterxml.jackson.module")
}

interface JunitDefaults: DependencyGroup {
    override val groupId get() = "org.junit.jupiter"
    override val version get() = "5.10.3"

    val api get() = dependency("junit-jupiter-api")
    val engine get() = dependency("junit-jupiter-engine")
    val params get() = dependency("junit-jupiter-params")
}

interface JjwtDefaults: DependencyGroup {
    override val groupId get() = "io.jsonwebtoken"
    override val version get() = "0.12.6"

    val api get() = dependency("jjwt-api")
    val impl get() = dependency("jjwt-impl")
    val jackson get() = dependency("jjwt-jackson")
    val orgjson get() = dependency("jjwt-orgjson")
}

interface KafkaDefaults: DependencyGroup {
    override val groupId get() = "org.apache.kafka"
    override val version get() = "3.8.0"

    val clients get() = dependency("kafka-clients")
    val kafka_2_12 get() = dependency("kafka_2.12")
    val streams get() = dependency("kafka-streams")
}

interface KluentDefaults: DependencyGroup {
    override val groupId get() = "org.amshove.kluent"
    override val version get() = "1.73"

    val kluent get() = dependency("kluent")
}

interface KotestDefaults: DependencyGroup {
    override val groupId get() = "io.kotest"
    override val version get() = "5.9.1"

    val runnerJunit5 get() = dependency("kotest-runner-junit5")
    val assertionsCore get() = dependency("kotest-assertions-core")
    val extensions get() = dependency("kotest-extensions")
}

interface KotlinDefaults: DependencyGroup {
    override val groupId get() = "org.jetbrains.kotlin"
    override val version get() = "2.0.0"

    val reflect get() = dependency("kotlin-reflect")
}

interface KotlinLoggingDefaults: DependencyGroup {
    override val groupId get() = "io.github.oshai"
    override val version get() = "7.0.0"

    val logging get() = dependency("kotlin-logging")
}

interface KotlinxDefaults: DependencyGroup {
    override val groupId get() = "org.jetbrains.kotlinx"

    val coroutines get() = dependency("kotlinx-coroutines-core", version = "1.8.1")
}

interface KotliQueryDefaults: DependencyGroup {
    override val groupId get() = "com.github.seratch"
    override val version get() = "1.9.0"

    val kotliquery get() = dependency("kotliquery")
}

object KtorDefaults {
    val version get() = "2.3.12"
    val groupId get() = "io.ktor"

    interface ServerDefaults: DependencyGroup {
        override val groupId get() = KtorDefaults.groupId
        override val version get() = KtorDefaults.version

        val core get() = dependency("ktor-server-core")
        val netty get() = dependency("ktor-server-netty")
        val defaultHeaders get() = dependency("ktor-server-default-headers")
        val metricsMicrometer get() = dependency("ktor-server-metrics-micrometer")
        val auth get() = dependency("ktor-server-auth")
        val authJwt get() = dependency("ktor-server-auth-jwt")
        val contentNegotiation get() = dependency("ktor-server-content-negotiation")
        val statusPages get() = dependency("ktor-server-status-pages")
        val htmlDsl get() = dependency("ktor-server-html-builder")
        val cors get() = dependency("ktor-server-cors")
    }

    interface ClientDefaults: DependencyGroup {
        override val groupId get() = KtorDefaults.groupId
        override val version get() = KtorDefaults.version

        val core get() = dependency("ktor-client-core")
        val apache get() = dependency("ktor-client-apache")
        val contentNegotiation get() = dependency("ktor-client-content-negotiation")
    }

    interface SerializationDefaults: DependencyGroup {
        override val groupId get() = KtorDefaults.groupId
        override val version get() = KtorDefaults.version

        val kotlinX get() = dependency("ktor-serialization-kotlinx-json")
        val jackson get() = dependency("ktor-serialization-jackson")
    }

    interface TestDefaults: DependencyGroup {
        override val groupId get() = KtorDefaults.groupId
        override val version get() = KtorDefaults.version

        val clientMock get() = dependency("ktor-client-mock")
        val serverTestHost get() = dependency("ktor-server-test-host")
    }
}

interface LogstashDefaults: DependencyGroup {
    override val groupId get() = "net.logstash.logback"
    override val version get() = "8.0"

    val logbackEncoder get() = dependency("logstash-logback-encoder")
}

interface MicrometerDefaults: DependencyGroup {
    override val groupId get() = "io.micrometer"
    override val version get() = "1.12.5"

    val registryPrometheus get() = dependency("micrometer-registry-prometheus")
}

interface MockkDefaults: DependencyGroup {
    override val groupId get() = "io.mockk"
    override val version get() = "1.13.12"

    val mockk get() = dependency("mockk")
}

interface PostgresqlDefaults: DependencyGroup {
    override val groupId get() = "org.postgresql"
    override val version get() = "42.7.3"

    val postgresql get() = dependency("postgresql")
}

interface PrometheusDefaults: DependencyGroup {
    override val version get() = "0.16.0"
    override val groupId get() = "io.prometheus"

    val common get() = dependency("simpleclient_common")
    val hotspot get() = dependency("simpleclient_hotspot")
    val httpServer get() = dependency("simpleclient_httpserver")
    val logback get() = dependency("simpleclient_logback")
    val simpleClient get() = dependency("simpleclient")
}

interface RapidsAndRiversDefaults: DependencyGroup {
    override val groupId get() = "com.github.navikt"
    override val version get() = "2024010209171704183456.6d035b91ffb4"

    val rapidsAndRivers get() = dependency("rapids-and-rivers")
}

interface ShadowDefaults: DependencyGroup {
    override val version get() = "8.1.1"

    val pluginId get() = "com.github.johnrengelman.shadow"
}

interface TestContainersDefaults: DependencyGroup {
    override val version get() = "1.20.0"
    override val groupId get() = "org.testcontainers"

    val junitJupiter get() = dependency("junit-jupiter")
    val testContainers get() = dependency("testcontainers")
    val postgresql get() = dependency("postgresql")
}

interface TmsCommonLibDefaults: DependencyGroup {
    override val groupId get() = "no.nav.tms.common"
    override val version get() = "4.0.2"

    val metrics get() = dependency("metrics")
    val observability get() = dependency("observability")
    val utils get() = dependency("utils")
    val kubernetes get() = dependency("kubernetes")
    val testutils get () = dependency("testutils")
}

interface TmsKafkaToolsDefaults: DependencyGroup {
    override val groupId get() = "no.nav.tms.kafka"
    override val version get() = "1.4.4"

    val kafkaApplication get() = dependency("kafka-application")
}

interface TmsKtorTokenSupportDefaults: DependencyGroup {
    override val groupId get() = "no.nav.tms.token.support"
    override val version get() = "4.1.2"

    val azureExchange get() = dependency("azure-exchange")
    val azureValidation get() = dependency("azure-validation")
    val tokenXValidation get() = dependency("tokenx-validation")
    val tokenXValidationMock get() = dependency("tokenx-validation-mock")
    val azureValidationMock get() = dependency("azure-validation-mock")
    val tokendingsExchange get() = dependency("tokendings-exchange")
    val idportenSidecar get() = dependency("idporten-sidecar")
    val idportenSidecarMock get() = dependency("idporten-sidecar-mock")
}

/*
2024-08-14 10:06:38: 7 outdated dependencies
io.micrometer:micrometer-registry-prometheus :  1.12.5 -> 1.13.3
org.flywaydb:flyway-core :  10.17.0 -> 10.17.1
org.jetbrains.kotlin.jvm:org.jetbrains.kotlin.jvm.gradle.plugin :  2.0.0 -> 2.0.10
org.junit.jupiter:junit-jupiter-api :  5.10.3 -> 5.11.0
org.junit.jupiter:junit-jupiter-params :  5.10.3 -> 5.11.0
org.testcontainers:postgresql :  1.20.0 -> 1.20.1
org.testcontainers:testcontainers :  1.20.0 -> 1.20.1
**Ignored dependencies
org.jetbrains.kotlin
org.gradle.kotlin.kotlin-dsl
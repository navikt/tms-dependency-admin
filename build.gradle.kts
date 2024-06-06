plugins {
    kotlin("jvm").version(Kotlin.version)

    `kotlin-dsl`
    `maven-publish`
}

repositories {
    mavenCentral()
}

kotlin {
    jvmToolchain {
        languageVersion.set(JavaLanguageVersion.of(17))
    }
}

dependencies {
    implementation(Flyway.core)
    implementation(Hikari.cp)
    implementation(JacksonDatatype.datatypeJsr310)
    implementation(Jjwt.api)
    implementation(Jjwt.impl)
    implementation(Jjwt.jackson)
    implementation(Jjwt.orgjson)
    implementation(Kafka.clients)
    implementation(Kafka.kafka_2_12)
    implementation(Kafka.streams)
    implementation(Kluent.kluent)
    implementation(Kotest.runnerJunit5)
    implementation(Kotest.assertionsCore)
    implementation(Kotest.extensions)
    implementation(Kotlin.reflect)
    implementation(KotlinLogging.logging)
    implementation(Kotlinx.coroutines)
    implementation(KotliQuery.kotliquery)
    implementation(Ktor.Server.core)
    implementation(Ktor.Server.netty)
    implementation(Ktor.Server.defaultHeaders)
    implementation(Ktor.Server.metricsMicrometer)
    implementation(Ktor.Server.auth)
    implementation(Ktor.Server.authJwt)
    implementation(Ktor.Server.contentNegotiation)
    implementation(Ktor.Server.statusPages)
    implementation(Ktor.Server.htmlDsl)
    implementation(Ktor.Server.cors)
    implementation(Ktor.Client.core)
    implementation(Ktor.Client.apache)
    implementation(Ktor.Client.contentNegotiation)
    implementation(Ktor.Serialization.kotlinX)
    implementation(Ktor.Serialization.jackson)
    implementation(Ktor.Test.clientMock)
    implementation(Ktor.Test.serverTestHost)
    implementation(Logstash.logbackEncoder)
    implementation(Micrometer.registryPrometheus)
    implementation(Postgresql.postgresql)
    implementation(Prometheus.common)
    implementation(Prometheus.hotspot)
    implementation(Prometheus.httpServer)
    implementation(Prometheus.logback)
    implementation(Prometheus.simpleClient)
}

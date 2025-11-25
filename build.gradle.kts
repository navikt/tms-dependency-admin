import com.github.benmanes.gradle.versions.updates.DependencyUpdatesTask

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
        languageVersion.set(JavaLanguageVersion.of(21))
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
    implementation(Logback.classic)
    implementation(Logstash.logbackEncoder)
    implementation(Micrometer.registryPrometheus)
    implementation(Postgresql.postgresql)
    implementation(Prometheus.metricsCore)
    implementation(Prometheus.exporterCommon)
    implementation(Jjwt.api)
    implementation(Jjwt.impl)
    implementation(Jjwt.jackson)
    implementation(Jjwt.orgjson)
    implementation(KotlinLogging.logging)
    implementation(KotliQuery.kotliquery)
    implementation(Logstash.logbackEncoder)
    //TODO
    //implementation(TmsCommonLib.metrics)
    //implementation(TmsCommonLib.utils)
    //implementation(TmsKafkaTools.kafkaApplication)
    //implementation(TmsKtorTokenSupport.tokenXValidation)
    //implementation(TmsKtorTokenSupport.tokendingsExchange)
    //implementation(TmsKtorTokenSupport.azureExchange)
    //implementation(TmsKtorTokenSupport.azureValidation)


    testImplementation(TestContainers.testContainers)
    testImplementation(TestContainers.postgresql)
    testImplementation(Mockk.mockk)
    testImplementation(JunitJupiter.api)
    testImplementation(JunitJupiter.params)
    testImplementation(JunitJupiter.engine)
    testImplementation(JunitPlatform.launcher)
    testImplementation(Kotest.runnerJunit5)
    testImplementation(Kotest.assertionsCore)
    testImplementation(Kotest.extensions)
    //testImplementation(TmsKtorTokenSupport.tokenXValidationMock)
    //testImplementation(TmsKtorTokenSupport.azureValidationMock)
}

buildscript {
    repositories {
        // Use 'gradle install' to install latest
        mavenLocal()
        gradlePluginPortal()
    }

    dependencies {
        classpath("com.github.ben-manes:gradle-versions-plugin:+")
    }
}
apply(plugin = "com.github.ben-manes.versions")

tasks.named<Test>("test") {
    // Use JUnit Platform for unit tests.
    useJUnitPlatform()
    environment ("ADMIN_GROUP" to "test_admin")
}
fun isNonStable(version: String): Boolean {
    val stableKeyword = listOf("RELEASE", "FINAL", "GA").any { version.uppercase().contains(it) }
    val regex = "^[0-9,.v-]+(-r)?$".toRegex()
    val isStable = stableKeyword || regex.matches(version)
    return isStable.not()
}

tasks.named<DependencyUpdatesTask>("dependencyUpdates").configure {

    // optional parameters
    checkForGradleUpdate = true
    outputFormatter = "json"
    outputDir = "build/dependencyUpdates"
    reportfileName = "dependencies"

    rejectVersionIf {
        isNonStable(candidate.version)
    }
}

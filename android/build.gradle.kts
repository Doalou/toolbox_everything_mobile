import org.gradle.api.tasks.compile.JavaCompile
import java.text.SimpleDateFormat
import java.util.*
// Déplacez la résolution de dépôts dans settings.gradle.kts (dependencyResolutionManagement)

val newBuildDir: Directory = rootProject.layout.buildDirectory.dir("../../build").get()
rootProject.layout.buildDirectory.value(newBuildDir)

// Reproducible builds: Fix build timestamp (epoch ms)
val buildTimeEpochMs: Long = System.getenv("SOURCE_DATE_EPOCH")
    ?.toLongOrNull()
    ?.times(1000)
    ?: SimpleDateFormat("yyyy-MM-dd HH:mm:ss").parse("2024-01-01 00:00:00").time

extra["buildTimeEpochMs"] = buildTimeEpochMs

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}
subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}

// Harmonise la version Java utilisée par tous les sous‑projets pour éviter
// les avertissements "source/target value 8 is obsolete"
subprojects {
    tasks.withType<JavaCompile>().configureEach {
        sourceCompatibility = JavaVersion.VERSION_17.toString()
        targetCompatibility = JavaVersion.VERSION_17.toString()
        // Reproducible builds: deterministic compiler arguments
        options.compilerArgs.addAll(listOf(
            "-Xlint:-options",
            "-XDuseUnsharedTable=true"
        ))
        // Fix file ordering for reproducible builds
        options.isIncremental = false
    }
    
    // Ensure reproducible JAR/AAR archives
    tasks.withType<AbstractArchiveTask>().configureEach {
        isPreserveFileTimestamps = false
        isReproducibleFileOrder = true
        dirMode = 493 // 0755 in octal
        fileMode = 420 // 0644 in octal
    }
}

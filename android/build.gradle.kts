import org.gradle.api.tasks.compile.JavaCompile
// Déplacez la résolution de dépôts dans settings.gradle.kts (dependencyResolutionManagement)

val newBuildDir: Directory = rootProject.layout.buildDirectory.dir("../../build").get()
rootProject.layout.buildDirectory.value(newBuildDir)

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
        // Pour supprimer explicitement l'avertissement lié aux options obsolètes :
        // options.compilerArgs.add("-Xlint:-options")
    }
}

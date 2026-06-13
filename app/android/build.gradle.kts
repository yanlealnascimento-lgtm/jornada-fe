allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

val newBuildDir: Directory =
    rootProject.layout.buildDirectory
        .dir("../../build")
        .get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}
subprojects {
    project.evaluationDependsOn(":app")
}

// Fix: isar_flutter_libs 3.x não define namespace, exigido pelo AGP 8+
// e usa compileSdkVersion 30, que não conhece atributos do AGP/AndroidX
// mais recentes (ex: android:attr/lStar), causando falha no AAPT.
gradle.afterProject {
    if (plugins.hasPlugin("com.android.library")) {
        val android = extensions.findByType(com.android.build.gradle.LibraryExtension::class.java)
        if (android?.namespace == null) {
            android?.namespace = group.toString()
        }
        android?.compileSdk = 35
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}

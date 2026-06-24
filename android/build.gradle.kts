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
    // Force all Android plugin subprojects (e.g. :geocoding_android) to compile against
    // a recent SDK. Some AndroidX deps now require compileSdk 34+, and plugin modules
    // don't inherit the app's compileSdk. Reflection avoids needing AGP types on the
    // root buildscript classpath. Registered before evaluationDependsOn so the hook is
    // in place before the projects are evaluated.
    afterEvaluate {
        project.extensions.findByName("android")?.let { android ->
            val method = android.javaClass.getMethod("compileSdkVersion", Int::class.javaPrimitiveType)
            method.invoke(android, 36)
        }
    }
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}

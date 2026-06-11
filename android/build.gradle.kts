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

// ✅ Remplacement sécurisé et correction forcée des dépendances comme fluttertoast
subprojects {
    afterEvaluate {
        val subproject = this
        if (subproject.plugins.hasPlugin("com.android.library") || subproject.plugins.hasPlugin("com.android.application")) {
            val androidExtension = subproject.extensions.findByName("android") as? com.android.build.api.dsl.CommonExtension<*, *, *, *, *, *>
            androidExtension?.apply {
                compileSdk = 36
                defaultConfig {
                    minSdk = 24
                }
            }
        }
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
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

// Force plugin modules (e.g. older geocoding_android) onto compileSdk 36.
subprojects {
    afterEvaluate {
        val androidExt = extensions.findByName("android") ?: return@afterEvaluate
        runCatching {
            val method =
                androidExt.javaClass.methods.firstOrNull { m ->
                    (m.name == "setCompileSdkVersion" || m.name == "setCompileSdk") &&
                        m.parameterCount == 1
                } ?: return@runCatching
            val param = method.parameterTypes[0]
            when {
                param == Int::class.javaPrimitiveType || param == Int::class.javaObjectType ->
                    method.invoke(androidExt, 36)
                param == Integer::class.java -> method.invoke(androidExt, Integer.valueOf(36))
                else -> method.invoke(androidExt, 36)
            }
        }
    }
}

subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}

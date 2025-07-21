buildscript {
    dependencies {
        classpath("com.google.gms:google-services:4.3.15") // Google Services plugin for Firebase
    }
    repositories {
        google()
        mavenCentral()
    }
}
allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.buildDir)
}
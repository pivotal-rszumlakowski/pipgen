package io.pivotal.masterpipeline.pipgen

class Job(jobHash: String) {

    init {
        if(jobHash.isEmpty()) {
            throw IllegalArgumentException("Empty job definition")
        }
    }

}
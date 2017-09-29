package io.pivotal.masterpipeline.pipgen

import org.junit.Test
import kotlin.test.assertFailsWith

class JobTest {

    @Test
    fun testEmptyDefinition() {
        assertFailsWith(
                exceptionClass = IllegalArgumentException::class,
                message = "Empty job definition",
                block = {Job("")})
    }
}
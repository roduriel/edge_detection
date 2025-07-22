package com.rodrigoceh.edgedetection


import com.rodrigoceh.edgedetection.processor.Corners
import org.opencv.core.Mat

class SourceManager {
    companion object {
        var pic: Mat? = null
        var corners: Corners? = null
    }
}
package com.rodrigoceh.edgedetection.crop

import android.widget.ImageView
import com.rodrigoceh.edgedetection.view.PaperRectangle


/**
 * Created by pengke on 15/09/2017.
 */
class ICropView {
    interface Proxy {
        fun getPaper(): ImageView
        fun getPaperRect(): PaperRectangle
        fun getCroppedPaper(): ImageView
    }
}
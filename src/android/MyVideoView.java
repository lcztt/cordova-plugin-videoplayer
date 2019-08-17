package com.vitas.videoplayer;

import android.content.Context;
import android.util.AttributeSet;
import android.util.Log;
import android.view.KeyEvent;
import android.widget.VideoView;

public class MyVideoView extends VideoView {

    private static final String TAG = "MyVideoView";

    private int mWidth;
    private int mHeight;


    public MyVideoView(Context context) {
        this(context, null);
    }

    public MyVideoView(Context context, AttributeSet attrs) {
        this(context, attrs, 0);
    }

    public MyVideoView(Context context, AttributeSet attrs, int defStyleAttr) {
        super(context, attrs, defStyleAttr);
    }

    @Override
    protected void onMeasure(int widthMeasureSpec, int heightMeasureSpec) {
        super.onMeasure(widthMeasureSpec, heightMeasureSpec);

        int width = getDefaultSize(getWidth(), widthMeasureSpec);
        int height = getDefaultSize(getHeight(), heightMeasureSpec);

        if (this.mWidth > 0 && this.mHeight > 0) {
            if (mWidth * height > width * mHeight) {
                height = width * mHeight / mWidth;
            } else if (mWidth * height < width * mHeight) {
                width = height * mWidth / mHeight;
            }
        }
        setMeasuredDimension(width, height);
    }

    public void setMeasure(int width, int height) {
        this.mWidth = width;
        this.mHeight = height;
    }

    @Override
    public boolean onKeyDown(int keyCode, KeyEvent event) {
        Log.e(TAG, "onKeyDown: dasdaaa111111111");
        return true;
    }
}

package com.vitas.videoplayer;

import android.annotation.SuppressLint;
import android.app.Activity;
import android.content.Context;
import android.graphics.Color;
import android.media.AudioManager;
import android.media.MediaPlayer;
import android.net.Uri;
import android.os.Build;
import android.support.annotation.RequiresApi;
import android.util.Log;
import android.util.TypedValue;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.webkit.WebSettings;
import android.webkit.WebView;
import android.widget.RelativeLayout;

import org.apache.cordova.CallbackContext;
import org.apache.cordova.CordovaInterface;
import org.apache.cordova.CordovaPlugin;
import org.apache.cordova.CordovaWebView;
import org.json.JSONArray;
import org.json.JSONException;
import org.json.JSONObject;

import bobo.chatapp.R;

import static android.content.Context.AUDIO_SERVICE;

/**
 * This class echoes a string called from JavaScript.
 */
public class videoplayer extends CordovaPlugin implements MediaPlayer.OnCompletionListener,
        MediaPlayer.OnPreparedListener, MediaPlayer.OnErrorListener {

    private static final String TAG = "videoplayer";

    private Context mContext;
    private Activity activity;
    private CordovaInterface cordova;
    private CordovaWebView cordovaWebView;
    private ViewGroup rootView;
    private WebView webView;
    private WebSettings settings;
    private CallbackContext mCallbackContext;

    private RelativeLayout rl_base;
    private MyVideoView view_video;
    private MediaPlayer mMediaPlayer;

    private String mVideoUrl;

    @Override
    public void initialize(CordovaInterface cordova, CordovaWebView webView) {
        super.initialize(cordova, webView);
        Log.e(TAG, "initialize: videoplayer 插件 开始初始化 ......");
        this.cordovaWebView = webView;
        this.cordova = cordova;
        this.activity = cordova.getActivity();
        this.mContext = this.activity.getApplicationContext();
        this.rootView = (ViewGroup) activity.findViewById(android.R.id.content);
        this.webView = (WebView) rootView.getChildAt(0);
        //activity.runOnUiThread(new Runnable() {
        //    @Override
        //    public void run() {
        //        rootView.setBackgroundColor(Color.BLACK);
        //    }
        //});
    }

    @Override
    public boolean execute(String action, JSONArray args, CallbackContext callbackContext) throws JSONException {
        this.mCallbackContext = callbackContext;
        Log.e(TAG, "execute: ------- " + action);
        switch (action) {
            case "playVideo":
                JSONObject jsonObject = new JSONObject(args.getString(0));
                mVideoUrl = jsonObject.optString("videoPath");
                Log.e(TAG, "execute: --------- " + mVideoUrl);
                initVideoView();
                return true;
            case "closeVideo":
                closeVideo();
                return true;
            case "pauseVideo":

                return true;
            case "replay":
                replay();
                return true;
            case "mute":
                JSONObject muteJsonObject = new JSONObject(args.getString(0));
                boolean openAudio = muteJsonObject.optInt("mute") == 0;
                return setMute(openAudio);
        }
        return true;
    }

    private void replay() {
        view_video.requestFocus();
        view_video.start();
        backPlugin(1);
    }

    private void pause() {
        Log.d(TAG, "Pausing video.");
        view_video.pause();
    }

    private void stop() {
        view_video.stopPlayback();
    }

    private boolean setMute(boolean openAudio) {
        if (mMediaPlayer != null) {
            float volume;
            if (openAudio) {
                AudioManager am = (AudioManager) mContext.getSystemService(AUDIO_SERVICE);
                int volumeLevel = am.getStreamVolume(AudioManager.STREAM_MUSIC);
                int maxVolume = am.getStreamMaxVolume(AudioManager.STREAM_MUSIC);
                volume = (float) volumeLevel / maxVolume;
            } else {
                volume = 0f;
            }
            mMediaPlayer.setVolume(volume, volume);
            mCallbackContext.success();
            return true;
        }
        mCallbackContext.error("mMediaPlayer is null");
        return true;
    }

    private void closeVideo() {
        activity.runOnUiThread(new Runnable() {
            @RequiresApi(api = Build.VERSION_CODES.LOLLIPOP)
            @Override
            public void run() {
                //StatusUtil.restoreStatusBar(activity, rootView);

                stop();
                if (rl_base == null) return;
                rootView.removeView(rl_base);
                rl_base = null;
                mMediaPlayer = null;
                webView.setBackgroundResource(0);
                webView.setLayerType(View.LAYER_TYPE_HARDWARE, null);
            }
        });
    }


    @Override
    public void onPrepared(MediaPlayer mp) {
        Log.d(TAG, "Stream is prepared");
        mMediaPlayer = mp;
        mp.setOnInfoListener(new MediaPlayer.OnInfoListener() {
            @Override
            public boolean onInfo(MediaPlayer mp, int what, int extra) {
                Log.e(TAG, "onInfo: -----------------------" + what);
                if (what == MediaPlayer.MEDIA_INFO_VIDEO_RENDERING_START)
                    backEvent(1, new JSONObject());
                return true;
            }
        });
        mp.setOnVideoSizeChangedListener(new MediaPlayer.OnVideoSizeChangedListener() {
            @Override
            public void onVideoSizeChanged(MediaPlayer mp, int width, int height) {
                int w = mp.getVideoWidth();
                int h = mp.getVideoHeight();
                Log.e(TAG, "onVideoSizeChanged: 视频宽高 " + w + "   " + h);
                view_video.setMeasure(w, h);
                view_video.requestLayout();
            }
        });

        view_video.requestFocus();
        view_video.start();
    }

    @Override
    public void onCompletion(MediaPlayer mp) {
        Log.d(TAG, "onCompletion triggered.");
        backEvent(3, new JSONObject());
    }

    @Override
    public boolean onError(MediaPlayer mp, int what, int extra) {
        StringBuilder sb = new StringBuilder();
        sb.append("MediaPlayer Error: ");
        switch (what) {
            case MediaPlayer.MEDIA_ERROR_NOT_VALID_FOR_PROGRESSIVE_PLAYBACK:
                sb.append("Not Valid for Progressive Playback");
                break;
            case MediaPlayer.MEDIA_ERROR_SERVER_DIED:
                sb.append("Server Died");
                break;
            case MediaPlayer.MEDIA_ERROR_UNKNOWN:
                sb.append("Unknown");
                break;
            default:
                sb.append(" Non standard (");
                sb.append(what);
                sb.append(")");
        }
        sb.append(" (" + what + ") ");
        sb.append(extra);
        Log.e(TAG, sb.toString());
        return false;
    }

    private void initVideoView() {
        if (rl_base != null) return;
        activity.runOnUiThread(new Runnable() {
            @Override
            public void run() {
                //StatusUtil.setTransparent(activity, rootView);
                LayoutInflater layoutInflater = LayoutInflater.from(activity);
                rl_base = (RelativeLayout) layoutInflater.inflate(_R("layout", "view_video_play"), null);
                view_video = rl_base.findViewById(R.id.view_video);
                rootView.addView(rl_base);
                rl_base.setVisibility(View.VISIBLE);
                webView.setBackgroundColor(Color.TRANSPARENT);
                // 关闭 webView 的硬件加速（否则不能透明）
                webView.setLayerType(WebView.LAYER_TYPE_SOFTWARE, null);
                webView.bringToFront();

                Uri videoUri = Uri.parse(mVideoUrl);
                view_video.setOnCompletionListener(videoplayer.this);
                view_video.setOnPreparedListener(videoplayer.this);
                view_video.setOnErrorListener(videoplayer.this);
                view_video.setVideoURI(videoUri);
            }
        });
    }

    public int _R(String defType, String name) {
        return activity.getApplication().getResources().getIdentifier(
                name, defType, activity.getApplication().getPackageName());
    }

    public void backPlugin(int status) {
        try {
            JSONObject jsonObject = new JSONObject();
            jsonObject.put("status", status);
            mCallbackContext.success(jsonObject);
        } catch (Exception e) {
            e.printStackTrace();
        }
    }

    private void backEvent(int eventID, JSONObject jsonObject) {
        @SuppressLint("DefaultLocale") final String jsStr =
                String.format("window.videoplayer.onVideoPlayEvent(%d, %s)", eventID, jsonObject.toString());
        activity.runOnUiThread(new Runnable() {
            @Override
            public void run() {
                cordovaWebView.loadUrl("javascript:" + jsStr);
            }
        });
    }

    public int dp2px(Context context, float dpVal) {
        return (int) TypedValue.applyDimension(TypedValue.COMPLEX_UNIT_DIP,
                dpVal, context.getResources().getDisplayMetrics());
    }

}

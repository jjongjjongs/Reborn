package com.reborn.updater;

import android.app.Activity;
import android.content.Intent;
import android.net.Uri;
import android.os.Build;
import android.provider.Settings;
import android.util.Log;

import androidx.core.content.FileProvider;

import org.godotengine.godot.Godot;
import org.godotengine.godot.plugin.GodotPlugin;
import org.godotengine.godot.plugin.UsedByGodot;

import java.io.File;

/**
 * Hands a downloaded APK to the system package installer.
 * GDScript does the version check + download; this only does the last step,
 * because Android refuses file:// URIs (API 24+) and needs a FileProvider
 * content:// URI with the APK MIME type. Methods never throw across JNI:
 * they return "" on success or a short reason string on failure.
 */
public class RebornUpdater extends GodotPlugin {
    private static final String TAG = "RebornUpdater";

    public RebornUpdater(Godot godot) {
        super(godot);
    }

    @Override
    public String getPluginName() {
        return "RebornUpdater";
    }

    @UsedByGodot
    public boolean can_install() {
        Activity a = getActivity();
        if (a == null) return false;
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return true;
        try {
            return a.getPackageManager().canRequestPackageInstalls();
        } catch (Throwable t) {
            Log.w(TAG, "canRequestPackageInstalls failed", t);
            return false;
        }
    }

    @UsedByGodot
    public void open_install_settings() {
        Activity a = getActivity();
        if (a == null) return;
        try {
            Intent i = new Intent(Settings.ACTION_MANAGE_UNKNOWN_APP_SOURCES,
                    Uri.parse("package:" + a.getPackageName()));
            i.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK);
            a.startActivity(i);
        } catch (Throwable t) {
            try {
                Intent i = new Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS,
                        Uri.parse("package:" + a.getPackageName()));
                i.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK);
                a.startActivity(i);
            } catch (Throwable t2) {
                Log.w(TAG, "cannot open install settings", t2);
            }
        }
    }

    @UsedByGodot
    public String install_apk(String path) {
        try {
            Activity a = getActivity();
            if (a == null) return "no activity";
            File f = new File(path);
            if (!f.exists() || f.length() == 0) return "file missing";
            if (!can_install()) return "permission";
            // reuse the FileProvider godot-lib already declares (files-path "/")
            Uri uri = FileProvider.getUriForFile(a, a.getPackageName() + ".fileprovider", f);
            Intent i = new Intent(Intent.ACTION_VIEW);
            i.setDataAndType(uri, "application/vnd.android.package-archive");
            i.addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION | Intent.FLAG_ACTIVITY_NEW_TASK);
            a.startActivity(i);
            return "";
        } catch (Throwable t) {
            Log.w(TAG, "install_apk failed", t);
            return String.valueOf(t.getMessage());
        }
    }
}

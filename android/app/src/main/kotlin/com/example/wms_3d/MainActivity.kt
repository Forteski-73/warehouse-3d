package com.example.wms_3d

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.android.RenderMode

// Some heavily customized OEM ROMs (observed on a Lenovo tablet running the
// ZUI skin) mishandle the SurfaceView Flutter uses to render by default,
// resulting in a blank screen even though the engine renders correctly.
// TextureView renders through the normal View hierarchy instead of a
// separate hardware overlay/surface, which is more compatible with that
// kind of aggressive window-management customization.
class MainActivity : FlutterActivity() {
    override fun getRenderMode(): RenderMode = RenderMode.texture
}

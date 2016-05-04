package priori.scene.manager;

import priori.scene.view.preload.PriPreloadSceneDefault;
import priori.assets.AssetManagerEvent;
import priori.scene.view.preload.PriPreloadScene;
import priori.assets.AssetManager;
import priori.scene.view.PriScene;
import priori.event.PriEvent;
import priori.app.PriApp;
import priori.view.container.PriContainer;

class SceneManager {

    private var currentScene:PriScene;
    private var sceneContainer:PriContainer;

    private var sceneHistory:Array<{scene:Class<PriScene>, args:Array<Dynamic>}>;

    private var isPreloading:Bool;

    public function new() {
        if (_g == null) {
            _g = this;
        } else {
            throw "Use static .g() method";
        }

        PriApp.g().addEventListener(PriEvent.RESIZE, this.onAppResize);

        this.isPreloading = false;
        this.sceneHistory = [];

        this.sceneContainer = new PriContainer();
        this.sceneContainer.clipping = true;
    }

    public function getContainer():PriContainer {
        return this.sceneContainer;
    }

    public function preload(startScene:Class<PriScene>, ?args:Array<Dynamic> = null, ?preloadScene:Class<PriPreloadScene> = null, ?onError:Void->Void = null):Void {
        if (preloadScene == null) preloadScene = PriPreloadSceneDefault;

        AssetManager.g().addEventListener(AssetManagerEvent.ASSET_COMPLETE, function(e:AssetManagerEvent):Void {
            this.isPreloading = false;

            AssetManager.g().removeAllEventListenersFromType(AssetManagerEvent.ASSET_COMPLETE);
            AssetManager.g().removeAllEventListenersFromType(AssetManagerEvent.ASSET_ERROR);
            AssetManager.g().removeAllEventListenersFromType(AssetManagerEvent.ASSET_PROGRESS);

            this.open(startScene, args, true);
        });

        AssetManager.g().addEventListener(AssetManagerEvent.ASSET_ERROR, function(e:AssetManagerEvent):Void {
            this.isPreloading = false;

            AssetManager.g().removeAllEventListenersFromType(AssetManagerEvent.ASSET_COMPLETE);
            AssetManager.g().removeAllEventListenersFromType(AssetManagerEvent.ASSET_ERROR);
            AssetManager.g().removeAllEventListenersFromType(AssetManagerEvent.ASSET_PROGRESS);

            if (onError != null) {
                onError();
            }
        });

        AssetManager.g().addEventListener(AssetManagerEvent.ASSET_PROGRESS, function(e:AssetManagerEvent):Void {
            cast(this.currentScene, PriPreloadScene).updateProgress(e.percentLoaded);
        });

        this.open(cast preloadScene, [], true);
        cast(this.currentScene, PriPreloadScene).updateProgress(0);

        this.isPreloading = true;

        AssetManager.g().load();
    }

    public function open(scene:Class<PriScene>, ?args:Array<Dynamic> = null, ?keepInHistory:Bool = true):Void {

        if (this.currentScene != null) {
            this.currentScene.removeFromParent();
            this.currentScene.kill();

            this.currentScene = null;
        }

        if (scene != null) {
            if (args == null) args = [];

            this.currentScene = Type.createInstance(scene, args);

            this.sceneContainer.addChild(this.currentScene);

            if (this.sceneContainer.parent != PriApp.g()) {
                PriApp.g().addChild(this.sceneContainer);
            }

            if (keepInHistory == true) {
                this.sceneHistory.push({
                    scene : scene,
                    args : args
                });
            }
        }

        this.onAppResize(null);
    }

    private function onAppResize(e:PriEvent):Void {
        var w:Float = PriApp.g().width;
        var h:Float = PriApp.g().height;

        this.sceneContainer.width = w;
        this.sceneContainer.height = h;

        if (this.currentScene != null) {
            this.currentScene.width = w;
            this.currentScene.height = h;

            this.currentScene.validate();
        }
    }

    private static var _g:SceneManager;
    public static function g():SceneManager {
        if (_g == null) _g = new SceneManager();
        return _g;
    }
}

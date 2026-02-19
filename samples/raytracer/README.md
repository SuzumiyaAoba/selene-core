# Scheme Ray Tracer Sample

シンプルなレイトレーサーの Scheme 実装です。球体をレイトレーシングして PPM 画像を出力します。

## 特徴

- **3D ベクトル演算**: 加算、減算、スカラー倍、内積、正規化
- **レイと球の交差判定**: 数学的な交差判定アルゴリズム
- **シェーディング**: 法線ベースのシンプルなシェーディング
- **PPM 画像出力**: 標準的な PPM (Portable Pixmap) 形式で出力

## 実装内容

### raytracer.scm の構成

1. **ベクトル演算** (vec3, vec-add, vec-sub, vec-scale, vec-dot, vec-normalize)
2. **レイ定義** (make-ray, ray-at)
3. **球体定義** (make-sphere, hit-sphere)
4. **シーン管理** (find-closest-hit)
5. **色計算** (ray-color, color-to-rgb)
6. **レンダリング** (render-scene, raytrace)
7. **PPM 出力** (output-ppm)

## デフォルトシーン

以下の4つの球体を含むシーンをレンダリングします:

- 赤い球 (中央)
- 緑の球 (左)
- 青い球 (右)
- 黄色い大きな球 (地面)

背景は青から白へのグラデーションです。

## 使い方

selene-core インタプリタで `raytracer.scm` を実行します。

```bash
cd /path/to/selene-core

# レイトレーサーを実行して output.ppm に保存
cat samples/raytracer/raytracer.scm | moon run repl > output.ppm
```

## 画像の確認

生成された PPM ファイルを確認する方法:

### macOS の場合:
```bash
open output.ppm
```

### PNG に変換 (ImageMagick が必要):
```bash
convert output.ppm output.png
open output.png
```

### オンラインビューア:
PPM ファイルを https://www.photopea.com/ などのオンラインエディタで開く

## カスタマイズ

### 画像サイズの変更

`raytracer.scm` の最後の行を編集:

```scheme
;; 元のサイズ (40x20)
(raytrace 40 20)

;; 高解像度版 (200x100) - レンダリング時間が長くなります
(raytrace 200 100)
```

### 球体の追加

`raytrace` 関数内の `spheres` リストに追加:

```scheme
(let ((spheres (list
                (make-sphere (vec3 0 0 -1) 0.5 (vec3 0.8 0.3 0.3))    ;; 赤
                (make-sphere (vec3 -1 0 -1) 0.5 (vec3 0.3 0.8 0.3))   ;; 緑
                (make-sphere (vec3 1 0 -1) 0.5 (vec3 0.3 0.3 0.8))    ;; 青
                (make-sphere (vec3 0 -100.5 -1) 100 (vec3 0.8 0.8 0.0))  ;; 地面
                ;; 新しい球体を追加
                (make-sphere (vec3 0 1 -1) 0.3 (vec3 1.0 0.5 0.0))    ;; オレンジ
                )))
```

球体のパラメータ:
- `center`: 中心座標 (vec3 x y z)
- `radius`: 半径
- `color`: 色 (vec3 r g b) - 各成分は 0.0 〜 1.0

### カメラ位置の変更

`render-scene` 関数内の `camera-center` を変更:

```scheme
(camera-center (vec3 0 0 0))  ;; デフォルト位置
(camera-center (vec3 0 1 0))  ;; 上から見下ろす
```

## パフォーマンス

- 40x20 ピクセル: 約 1-2 秒
- 100x50 ピクセル: 約 5-10 秒
- 200x100 ピクセル: 約 20-40 秒
- 400x200 ピクセル: 約 2-4 分

※ 実行時間はシステムの性能に依存します

## 技術的詳細

### レイトレーシングアルゴリズム

1. **カメラからレイを生成**: 各ピクセルに対応するレイを計算
2. **交差判定**: レイと各球体の交差をチェック
3. **最も近い交差点を選択**: 複数の交差がある場合、カメラに最も近いものを選択
4. **シェーディング計算**: 交差点の法線を使って色を計算
5. **背景色**: 交差しない場合、背景のグラデーションを返す

### 座標系

- X 軸: 右方向
- Y 軸: 上方向
- Z 軸: 奥方向（負の値が画面に向かう）

## 拡張アイデア

現在の実装はシンプルですが、以下の機能を追加できます:

1. **反射**: 鏡面反射を実装して再帰的にレイを追跡
2. **影**: 光源を追加してシャドウレイを実装
3. **平面**: 球体以外のプリミティブを追加
4. **アンチエイリアシング**: 各ピクセルで複数のサンプルを取る
5. **テクスチャ**: 表面に模様を追加
6. **フォーカス**: 被写界深度の実装

## 参考資料

- [Ray Tracing in One Weekend](https://raytracing.github.io/)
- [Scratchapixel](https://www.scratchapixel.com/)

## ライセンス

このサンプルコードは selene-core プロジェクトの一部として提供されています。

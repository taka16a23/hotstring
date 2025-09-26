# hotstring.el

`hotstring.el` は、Emacs で **ホットストリング**（特定の文字列を入力すると自動的に置換される機能）を提供するシンプルなパッケージです。  
たとえば `pyhton` と入力すると `python` に置き換えするといった使い方が可能です。

以下のデモをご覧ください。

![demo](https://raw.github.com/wiki/taka16a23/hotstring/images/demo.gif)

---

## 特徴

- 軽量で依存関係なし
- 任意の文字列を簡単に定義可能
- グローバル／モード単位での設定に対応
- Emacs 標準の `abbrev-mode` よりシンプルに利用可能

---

## インストール

本リポジトリをクローン、または `hotstring.el` をダウンロードしてください。

```bash
git clone https://github.com/taka16a23/hotstring.git
```
---

## hotstringライブラリ読み込みと有効化
```Emacs Lisp
(add-to-list 'load-path "/path/to/hotstring.el")
(require 'hotstring)
(hotstring-global-mode 1)
```
---

## 置き換え文字列の設定例
```Emacs Lisp
(custom-set-variables
   '(hots-global-table-predefine '(
     ("pyhton" . "python")
     ("slef"   . "self")
     ("eamcs"  . "emacs")
    )))
```

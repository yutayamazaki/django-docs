# Djangoのmiddlewareについて

|  |  |
|--|--|
| 更新日 | 2020-11-27 |
| Django | v3.1.3 |
| Django Rest Framework | v3.12.2 |

DjangoのmiddlewareはユーザーからのHTTPリクエストに対して常に実行されるpluginのことであり，大きくWSGI MiddlewreとDjango Middlewareに分類される．

- リクエストを受け取る
- WSGI Middleware
- Django Middleware
- Django View
- Django Middleware
- WSGI Middleware
- レスポンスを返す

Djangoは上記のような流れでHTTP通信を行うため，各APIに共通で実装したい処理などはmiddlewareとして記述することができる．

## Middlewareの設定

`settings.py`の`MIDDLEWARE`という変数でMiddlewareの設定を行う．Djangoのデフォルトでは以下の値が設定されている．

```python
MIDDLEWARE = [
    'django.middleware.security.SecurityMiddleware',
    'django.contrib.sessions.middleware.SessionMiddleware',
    'django.middleware.common.CommonMiddleware',
    'django.middleware.csrf.CsrfViewMiddleware',
    'django.contrib.auth.middleware.AuthenticationMiddleware',
    'django.contrib.messages.middleware.MessageMiddleware',
    'django.middleware.clickjacking.XFrameOptionsMiddleware',
]
```

このように各Middlewareへのフルパスを文字列で与えることでMiddlewareが実行される．Djangoはリクエストを受け取ると`MIDDLEWARE`に記述されたMiddlewareをListの先頭から順に実行し，Viewを経てレスポンスを返す際はListの逆順にMiddlewareの処理を実行する．

Djangoの公式ドキュメントに記載されている関数ベースのシンプルなMiddlewareの実装を見てみる．以下のようにget_responseというviewのhandlerを受け取り，requestを引数として受け取るCallableなオブジェクトを返せばそれでDjangoのMiddlewareとして機能する．

```python
def simple_middleware(get_response):

    def middleware(request):
        # Viewが呼ばれる前に実行したい処理を書く
        response = get_response(request)
        # Viewが呼ばれた後に実行したい処理を書く
        return response

    return middleware
```

またクラスベースでMiddlewareを記述することも可能で，Djangoの公式ドキュメントでは以下のような例が記載されている．

```python
class SimpleMiddleware:
    def __init__(self, get_response):
        self.get_response = get_response
        # One-time configuration and initialization.

    def __call__(self, request):
        # Viewが呼ばれる前に実行したい処理を書く
        response = self.get_response(request)
        # Viewが呼ばれた後に実行したい処理を書く
        return response
```

# Request

|  |  |
|--|--|
| 更新日 | 2020-11-25 |
| Django | v3.1.3 |
| Django Rest Framework | v3.12.2 |

## DjangoのRequestクラス

Djangoは受信したHTTPリクエストを[django.http.request.HTTPRequest](https://github.com/django/django/blob/master/django/http/request.py)で受け取り，それをもとにViewでの処理を行う．

Djangoの公式ドキュメントに掲載されているAPI実装の例が以下の「リクエストを受け取り，現在時刻を含むhtmlを返す」関数である．この関数の引数requestに入るHTTPリクエストの中身こそがDjangoの`HTTPRequest`であり，HTTPリクエストの中身をパースしてPythonのインスタンスにまとめあげたものである．

```python
from django.http import HttpResponse
import datetime

def current_datetime(request):
    now = datetime.datetime.now()
    html = "<html><body>It is now %s.</body></html>" % now
    return HttpResponse(html)
```

`HTTPRequest`クラスのメンバに関する詳細は[公式ドキュメント](https://docs.djangoproject.com/en/3.1/ref/request-response/#django.http.HttpRequest)を参照．

## DjangoのWSGIRequestからRequestがパースされる流れを知る

Djangoアプリケーションは[PEP333](https://www.python.org/dev/peps/pep-0333/)で定められたWSGIというインターフェースを介してサーバーとのやりとりを行う．その際に利用されるのがDjangoの`WSGIRequest`であり`WSGIServer`である．また`WSGIRequest`は`HTTPRequest`を継承したクラスである．

WSGIの仕様を簡単なコードを用いて確認する．

- `environ`と`start_response`という2つの引数を持ったCallableなオブジェクト
- 第2引数のオブジェクトを呼び出してstatus codeとheaderを渡す
- レスポンスは文字列を返すIterableオブジェクト

```python
def simple_app(environ, start_response):
    start_response('200 OK', [('Content-type', 'text/plain')])
    return ['Hello world!\n']


if __name__ == '__main__':
    from wsgiref import simple_server
    server = simple_server.make_server('', 8080, application)
    server.serve_forever()
```

WSGIに関する詳細は以下の文献を参照．

- [PEP 333 -- Python Web Server Gateway Interface v1.0 | Python.org](https://www.python.org/dev/peps/pep-0333/)
- [PEP 3333 -- Python Web Server Gateway Interface v1.0.1 | Python.org](https://www.python.org/dev/peps/pep-3333/)
- [WSGI について &#8212; Webアプリケーションフレームワークの作り方 in Python](https://c-bata.link/webframework-in-python/wsgi.html)

例のコードのenviron部分にリクエストに関する様々な情報が入り，その情報を適切にwrapしたものが`WSGIRequest`である．enrivon部分に入る情報の詳細は[PEP3333 environ-variables](https://www.python.org/dev/peps/pep-3333/#environ-variables)を参照．代表的なものには以下がある．

| 変数名 | 概要 |
|--|--|
| REQUEST_METHOD | GETやPOSTのようにHTTPリクエストのメソッド名の文字列 |
| PATH_INFO | URLのroot以降のpath |
| QUERY_STRING | URLエンコードされたパラメータの文字列でURLの?以降 |
| CONTENT_TYPE | HTTPリクエストに含まれるCOntent-Typeヘッダーの値 |

[WSGIRequestの実装](https://github.com/django/django/blob/master/django/core/handlers/wsgi.py)は以下のようになっている．ヘルパー関数の省略などはあるが，WSGIから渡されるenvironから`PATH_INFO`や`REUQEST_METHOD`などの値をパースして適切にクラスのメンバへ落とし込んでいることがわかる．

```python
class WSGIRequest(HttpRequest):
    def __init__(self, environ):
        script_name = get_script_name(environ)
        path_info = get_path_info(environ) or '/'
        self.environ = environ
        self.path_info = path_info
        self.path = '%s/%s' % (script_name.rstrip('/'),
                               path_info.replace('/', '', 1))
        self.META = environ
        self.META['PATH_INFO'] = path_info
        self.META['SCRIPT_NAME'] = script_name
        self.method = environ['REQUEST_METHOD'].upper()

        self._set_content_type_params(environ)
        try:
            content_length = int(environ.get('CONTENT_LENGTH'))
        except (ValueError, TypeError):
            content_length = 0
        self._stream = LimitedStream(self.environ['wsgi.input'], content_length)
        self._read_started = False
        self.resolver_match = None

    def _get_scheme(self):
        return self.environ.get('wsgi.url_scheme')

    @cached_property
    def GET(self):
        raw_query_string = get_bytes_from_wsgi(self.environ, 'QUERY_STRING', '')
        return QueryDict(raw_query_string, encoding=self._encoding)

    def _get_post(self):
        if not hasattr(self, '_post'):
            self._load_post_and_files()
        return self._post

    def _set_post(self, post):
        self._post = post

    @cached_property
    def COOKIES(self):
        raw_cookie = get_str_from_wsgi(self.environ, 'HTTP_COOKIE', '')
        return parse_cookie(raw_cookie)

    @property
    def FILES(self):
        if not hasattr(self, '_files'):
            self._load_post_and_files()
        return self._files

    POST = property(_get_post, _set_post)
```

Djangoではこのようにして初期化された`HTTPRequest`クラスを用いて適切にHTTPリクエストの情報を利用しながら処理を記述する．

## Django Rest FrameworkのRequestクラス

Under construction.

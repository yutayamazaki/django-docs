# django-docs

## Django Rest Frameworkで作るAPI

Django Rest Frameworkでは主に`rest_framework.views.APIView`を継承したviewクラスを作成することでAPIの実装を行う．また別の方法として関数型のviewを作成する`rest_framework.decorators.api_view`を利用する方法もあるが，こちらは`APIView`をデコレータで使える形にしたものであるため詳細な説明は省略する．

### APIView

`APIView`はdjangoに実装されている[django.views.generic.View](https://github.com/django/django/blob/master/django/views/generic/base.py)を継承して拡張したものになっている．主な違いとしては以下の点が挙げられる．

- viewのhandlerに`django.http.request.HttpRequest`ではなく`rest_framework.request.Request`が渡される
- viewのhandlerが`django.http.response.HTTPResponse`ではなく`rest_framework.response.Response`を返す
- `permission_classes`というメンバ変数に権限に関するclassを渡すことで簡単にリクエストに必要な権限を設定することができる

rest_frameworkの公式ドキュメントのAPIViewを用いた実装の例．このようにgetメソッドを実装することでUser.usernameに対するlistを簡単に実装することができる．

```python
class ListUsers(APIView):
    authentication_classes = [authentication.TokenAuthentication]
    permission_classes = [permissions.IsAdminUser]

    def get(self, request, format=None):
        usernames = [user.username for user in User.objects.all()]
        return Response(usernames)
```

上記例のようにHTTPリクエストのgetメソッドに対して`APIView`のgetメソッドが呼ばれる仕組みを解説する．

`APIView`はdjangoの`View`と同様に`dispatch`というメソッドがHTTPリクエストを受け付けて，HTTPメソッドの種類に応じて適切な処理を実行する．現在の`dispatch`の処理は以下の実装となっている．

```python
class APIView(View):

    ...

    def dispatch(self, request, *args, **kwargs):
        """
        `.dispatch()` is pretty much the same as Django's regular dispatch,
        but with extra hooks for startup, finalize, and exception handling.
        """
        self.args = args
        self.kwargs = kwargs
        request = self.initialize_request(request, *args, **kwargs)
        self.request = request
        self.headers = self.default_response_headers  # deprecate?

        try:
            self.initial(request, *args, **kwargs)

            # Get the appropriate handler method
            if request.method.lower() in self.http_method_names:
                handler = getattr(self, request.method.lower(),
                                  self.http_method_not_allowed)
            else:
                handler = self.http_method_not_allowed

            response = handler(request, *args, **kwargs)

        except Exception as exc:
            response = self.handle_exception(exc)

        self.response = self.finalize_response(request, response, *args, **kwargs)
        return self.response
```

`dispatch`の処理の大きな流れは以下となっている．

- djangoの`HTTPRequest`やその他HTTPリクエストの情報に含まれる情報を受け取り，rest_frameworkの`Request`インスタンスを作成する
- `initial`メソッド内でpermissionのチェックなどを行う
- 指定されたhttpメソッドのhandlerを取り出し，存在しない場合は`self.http_method_not_allowed`で405エラーを返す`rest_framework.exceptions.MethodNotAllowed`をhandlerとして取得する
- handler内部の処理を実行し，戻り値として受け取った`Response`インスタンスを返す

そのため`APIView`を継承したクラスでgetやpostなどのメソッドを実装することで，リクエストに応じた適切な処理が実行されるようになっている．

### GenericAPIViewとViewSet

rest_frameworkでDBに紐づく処理を記述する場合は`rest_framework.generics.GenericAPIView`を利用する．`GenericAPIView`は`rest_framework.views.APIView`を継承したクラスであり，APIを実装したいDBの`queryset`とそれをjsonに変換するための`serializer_class`メンバを持つ．

例えば`rest_framework.viewsets.ModelViewSet`を利用すると以下のコードでDBモデルに対する様々な処理を実装できる．(serializerに関する説明は省略)

```python
class UserViewSet(viewsets.ModelViewSet):

    serializer_class = UserSerializer
    queryset = User.objects.all()
```

上記コードで実装される処理の一覧．

| メソッド名 | 処理 |
|--|--|
| list | 全件取得 |
| retrive | 1件取得 |
| create | 作成 |
| update | 更新 |
| partial_update | 部分更新 |
| destroy | 削除 |

上記例のコード中で出てきた[rest_framework.viewsets.ModelViewSet](https://github.com/encode/django-rest-framework/blob/master/rest_framework/viewsets.py)は以下のコードで実装されている．

```python
class ModelViewSet(mixins.CreateModelMixin,
                   mixins.RetrieveModelMixin,
                   mixins.UpdateModelMixin,
                   mixins.DestroyModelMixin,
                   mixins.ListModelMixin,
                   GenericViewSet):
    pass
```

継承元となっている複数のmixinがそれぞれのDBに関連する処理のメソッドを実装しており，これらを継承することでDBに関連する処理を適切に実装することができる．例えばcreateとretrive以外は不要な状況では以下のように実装することでcreateとretrieveのみの処理を持ったViewSetを作成することができる．

```python
class UserViewSet(
    mixins.CreateModelMixin, 
    mixins.RetrieveModelMixin,
    viewsets.GenericViewSet
):

    serializer_class = UserSerializer
    queryset = User.objects.all()
```

それぞれのmixinクラスがどのようにquerysetとserializerを利用しているかの詳細は[GitHub](https://github.com/encode/django-rest-framework/blob/master/rest_framework/mixins.py)を参照．本記事では例として`rest_framework.mixins.RetriveModelMixin`の実装のみ確認する．

```python
class RetrieveModelMixin:

    def retrieve(self, request, *args, **kwargs):
        instance = self.get_object()
        serializer = self.get_serializer(instance)
        return Response(serializer.data)
```

- `get_object()`でquerysetメンバから適切なfiltering処理後のインスタンスを取得する
- 取得したインスタンスをserializerでjson形式に変換する
- `Response`インスタンスを返す

mixinとしてデフォルトで実装されていない処理を実装したい場合は適切なメソッド名に対して自身でコードを実装すればAPIViewのdiapatchがリクエストに対して適切な呼び出しを行ってくれる．(以下の例のようにDBに全く関係のない何もしない処理を書いてもいい)

```python
class UserViewSet(
    viewsets.GenericViewSet
):

    serializer_class = UserSerializer
    queryset = User.objects.all()

    def create(self, request, *args, **kwargs):
        return Response({'msg': 'Do nothing.'})
```

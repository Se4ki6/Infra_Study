function handler(event) {
  var request = event.request;
  var uri = request.uri;

  // 拡張子がないURLの場合、/index.html を付与
  if (uri.indexOf('/') !== -1) {
    request.uri = uri + '/index.html';
  }

  // URLが / で終わっている場合、index.html を付与
  if (uri.charAt(uri.length - 1) === '/') {
    request.uri = uri + 'index.html';
  }

  return request;
}

let comprasQrScanner = null;
let comprasQrScannerRodando = false;

window.comprasQrStart = function (onSuccess, onError) {
  const readerId = "qr-reader";
  const readerElement = document.getElementById(readerId);

  if (!readerElement) {
    if (onError) {
      onError("Elemento do leitor QR não encontrado na tela.");
    }
    return;
  }

  if (typeof Html5Qrcode === "undefined") {
    if (onError) {
      onError("Biblioteca html5-qrcode não foi carregada.");
    }
    return;
  }

  if (comprasQrScannerRodando) {
    return;
  }

  comprasQrScanner = new Html5Qrcode(readerId);

  Html5Qrcode.getCameras()
    .then(function (devices) {
      if (!devices || devices.length === 0) {
        if (onError) {
          onError("Nenhuma câmera foi encontrada.");
        }
        return;
      }

      const cameraId = devices[0].id;

      const config = {
        fps: 10,
        qrbox: {
          width: 250,
          height: 250,
        },
      };

      comprasQrScanner
        .start(
          cameraId,
          config,
          function (decodedText) {
            if (onSuccess) {
              onSuccess(decodedText);
            }

            window.comprasQrStop();
          },
          function () {
            // Erros de leitura por frame são normais.
            // Por isso não mostramos mensagem a cada tentativa.
          }
        )
        .then(function () {
          comprasQrScannerRodando = true;
        })
        .catch(function (error) {
          comprasQrScannerRodando = false;

          if (onError) {
            onError("Não foi possível iniciar a câmera: " + error);
          }
        });
    })
    .catch(function (error) {
      comprasQrScannerRodando = false;

      if (onError) {
        onError("Erro ao buscar câmeras: " + error);
      }
    });
};

window.comprasQrStop = function () {
  if (!comprasQrScanner || !comprasQrScannerRodando) {
    comprasQrScanner = null;
    comprasQrScannerRodando = false;
    return;
  }

  comprasQrScanner
    .stop()
    .then(function () {
      comprasQrScanner.clear();
      comprasQrScanner = null;
      comprasQrScannerRodando = false;
    })
    .catch(function () {
      comprasQrScanner = null;
      comprasQrScannerRodando = false;
    });
};
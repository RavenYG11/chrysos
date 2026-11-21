(() => {
  const assets = new URL('ocr/', document.currentScript.src);

  function loadEngine() {
    if (globalThis.Tesseract) return Promise.resolve();
    return new Promise((resolve, reject) => {
      const script = document.createElement('script');
      script.src = new URL('tesseract.min.js', assets).href;
      script.onload = resolve;
      script.onerror = () => {
        script.remove();
        reject(new Error('OCR engine could not be loaded.'));
      };
      document.head.append(script);
    });
  }

  // One worker per scan so photos and recognition state are released afterward.
  globalThis.chrysosRecognizeReceipt = async (bytes) => {
    await loadEngine();
    let worker;
    let timer;
    let expired = false;
    const recognition = async (reject) => {
      worker = await Tesseract.createWorker('ind', 1, {
        workerPath: new URL('worker.min.js', assets).href,
        corePath: new URL('tesseract-core-lstm.wasm.js', assets).href,
        langPath: assets.href,
        workerBlobURL: false,
        cacheMethod: 'none',
        errorHandler: reject,
      });
      if (expired) {
        await worker.terminate();
        return '';
      }
      const { data } = await worker.recognize(bytes);
      return data.text;
    };
    try {
      return await new Promise((resolve, reject) => {
        timer = setTimeout(() => {
          expired = true;
          reject(new Error('OCR timed out.'));
        }, 45000);
        recognition(reject).then(resolve, reject);
      });
    } finally {
      clearTimeout(timer);
      if (worker) await worker.terminate();
    }
  };
})();

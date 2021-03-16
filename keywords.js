async function getTexts(page, args) {
  const selector = args[0];
  return await page.$$eval(selector, (elements) =>
    elements.map((element) => element.innerText)
  );
}

exports.__esModule = true;
exports.getTexts = getTexts;

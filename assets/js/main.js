// Copy buttons on code blocks
document.querySelectorAll('div.highlighter-rouge').forEach(function (block) {
  var btn = document.createElement('button');
  btn.className = 'copy-btn';
  btn.type = 'button';
  btn.textContent = 'copy';
  btn.addEventListener('click', function () {
    var code = block.querySelector('pre code') || block.querySelector('pre');
    navigator.clipboard.writeText(code.innerText).then(function () {
      btn.textContent = 'copied';
      btn.classList.add('done');
      setTimeout(function () { btn.textContent = 'copy'; btn.classList.remove('done'); }, 1500);
    });
  });
  block.appendChild(btn);
});

// Category filter on /posts/ (also reads #category from the URL)
(function () {
  var buttons = document.querySelectorAll('.filter');
  if (!buttons.length) return;
  var items = document.querySelectorAll('.archive-item');
  var empty = document.querySelector('.empty');

  function apply(cat) {
    var shown = 0;
    buttons.forEach(function (b) { b.classList.toggle('is-active', b.dataset.filter === cat); });
    items.forEach(function (li) {
      var match = cat === 'all' || li.dataset.cat === cat;
      li.hidden = !match;
      if (match) shown++;
    });
    if (empty) empty.hidden = shown > 0;
  }

  buttons.forEach(function (b) {
    b.addEventListener('click', function () {
      apply(b.dataset.filter);
      history.replaceState(null, '', b.dataset.filter === 'all' ? location.pathname : '#' + b.dataset.filter);
    });
  });

  var initial = location.hash.slice(1);
  apply(initial || 'all');
})();

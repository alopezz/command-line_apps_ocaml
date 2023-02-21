Preview non-existing file displays an error
  $ mdp -file none
  Failed to read file: Sys_error("none: No such file or directory")
  [1]

Example file
  $ cat $(mdp -s -file test1.md)
  <!DOCTYPE html>
  <html>
    <head>
      <meta http-equiv="content-type" content="text/html; charset=utf-8">
      <title>Markdown Preview Tool: test1.md</title>
    </head>
    <body>
  <h1>Test Markdown File</h1>
  <p>Just a test</p>
  <h2>Bullets:</h2>
  <ul>
  <li>Links <a href="https://example.com" rel="nofollow">Link1</a>
  </li>
  </ul>
  <h2>Code Block</h2>
  <pre><code>some code
  </code></pre>
    </body>
  </html>

Example with custom template
  $ cat $(mdp -s -file test1.md -t custom_template.html)
  <!DOCTYPE html>
  <html>
    <head>
      <meta http-equiv="content-type" content="text/html; charset=utf-8">
      <title>Title: Markdown Preview Tool</title>
    </head>
    <body>
      And this is the body:
  <h1>Test Markdown File</h1>
  <p>Just a test</p>
  <h2>Bullets:</h2>
  <ul>
  <li>Links <a href="https://example.com" rel="nofollow">Link1</a>
  </li>
  </ul>
  <h2>Code Block</h2>
  <pre><code>some code
  </code></pre>
    </body>
  </html>
<h1>Test Markdown File</h1>
<p>Just a test</p>
<h2>Bullets:</h2>
<ul>
<li>Links <a href="https://example.com" rel="nofollow">Link1</a>
</li>
</ul>
<h2>Code Block</h2>
<pre><code>some code
</code></pre>
</html>

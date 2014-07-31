odoc-ltxhtml
======================

This is a custom generator for OCamldoc, a documentation generator of
[OCaml](http://ocaml.org/).
This allows developers to embed LaTeX equations in HTML output as images.
odoc-ltxhtml is distributed under MIT License.

Usage
-----

##### Compilation

```
$ make
```

##### Documentation Generation

```
ocamldoc -g ltxhtml.cma ...
```

odoc-ltxhtml converts raw LaTeX code in `{% ... %}` to a GIF image
and embeds it in generated HTML documentation.
The following notations are supported to write LaTeX equations:

- `{m{% ... %}}` is a syntactic sugar of `{% $ ... $%}`.
- `{eq{% ... %}}` is a syntactic sugar of `{% \\[ ... \\]%}`.

Simple Example
--------------

```
$ make example
```

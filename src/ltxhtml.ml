(* The MIT License (MIT)

   Copyright (c) 2014 Akinori ABE

   Permission is hereby granted, free of charge, to any person obtaining a copy
   of this software and associated documentation files (the "Software"), to deal
   in the Software without restriction, including without limitation the rights
   to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
   copies of the Software, and to permit persons to whom the Software is
   furnished to do so, subject to the following conditions:

   The above copyright notice and this permission notice shall be included in
   all copies or substantial portions of the Software.

   THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
   IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
   FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
   AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
   LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
   OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
   THE SOFTWARE.
 *)

open Printf
open Odoc_info

module Opt =
  struct
    let latex = ref "latex"
    let dvigif = ref "dvigif"
    let dir = ref "ltx"
    let resolution = ref 110
    let fg = ref "rgb 0.0 0.0 0.0"
    let bg = ref "rgb 1.0 1.0 1.0"
    let header = ref "\\documentclass{article}\n\
                      \\usepackage{amsmath}\n\
                      \\usepackage{amssymb}\n\
                      \\usepackage{amsfonts}\n\
                      \\usepackage{latexsym}\n\
                      \\usepackage{bm}\n\
                      \\usepackage{cases}\n\
                      \\pagestyle{empty}\n\
                      \\begin{document}\n"
    let footer = ref "\n\\end{document}\n"

    let () = [
      "-ltxhtml-latex", Arg.Set_string latex,
      sprintf "<cmd>\tSpecify the LaTeX command (default = %s)" !latex;
      "-ltxhtml-dvigif", Arg.Set_string dvigif,
      sprintf "<cmd>\tSpecify the dvigif command (default = %s)" !dvigif;
      "-ltxhtml-dir", Arg.Set_string dir,
      sprintf "<dir>\tGenerate image files in directory <dir> (default = %s)"
              !dir;
      "-ltxhtml-resolution", Arg.Set_int resolution,
      sprintf "<r>\n\t\t\tSpecify resolution <r> of generated LaTeX images \
               (default = %d)" !resolution;
      "-ltxhtml-fg", Arg.Set_string fg,
      sprintf "<color>\tForeground color of LaTeX images (TeX-style color \
               or 'Transparent') (default = %s)" !fg;
      "-ltxhtml-bg", Arg.Set_string bg,
      sprintf "<color>\tBackground color of LaTeX images (TeX-style color \
               or 'Transparent') (default = %s)" !bg;
      "-ltxhtml-header", Arg.Set_string header,
      sprintf "<tex-code>\n\t\t\tUse <tex-code> as the header of LaTeX files";
      "-ltxhtml-footer", Arg.Set_string footer,
      sprintf "<tex-code>\n\t\t\tUse <tex-code> as the footer of LaTeX files";
    ] |> List.iter Odoc_args.add_option
  end

module Ltxhtml_generator (G: Odoc_html.Html_generator)
       : Odoc_html.Html_generator =
  struct
    class html =
    object(self)
      inherit G.html as super

      val mutable ltximg = (Obj.magic () : Ltxhtml_ltximage.t)

      initializer
        default_style_options <- (* add style definitions to style.css *)
          "img.ltxhtml { vertical-align : middle }"
          :: default_style_options

      (** Generate all HTML files *)
      method generate module_list =
        let image_dir = Filename.concat (!Odoc_global.target_dir) !Opt.dir in
        if not (Sys.file_exists image_dir) then Unix.mkdir image_dir 0o755;
        ltximg <- Ltxhtml_ltximage.create image_dir;
        begin
          try
            super#generate module_list;
          with
          | Ltxhtml_ltximage.Command_error (cmd, msg) ->
             prerr_endline (cmd ^ "\n" ^ msg)
          | Failure msg -> prerr_endline msg
          | Sys_error msg -> prerr_endline msg
        end;
        Ltxhtml_ltximage.cleanup ltximg

      (** Generate a LaTeX image and a HTML tag *)
      method private html_of_Latex buffer code =
        let filename = Ltxhtml_ltximage.generate ltximg
                                                 ~latex:!Opt.latex
                                                 ~header:!Opt.header
                                                 ~footer:!Opt.footer
                                                 ~dvigif:!Opt.dvigif
                                                 ~fg:!Opt.fg ~bg:!Opt.bg
                                                 ~resolution:!Opt.resolution
                                                 code in
        let image_path = Filename.concat !Opt.dir filename in
        let html = sprintf "<img class=\"ltxhtml\" alt=\"%s\" src=\"%s\">"
                           (self#escape code) (self#escape image_path) in
        Buffer.add_string buffer html

      method html_of_custom_text b s t =
        match s with
        | "m" ->
           begin
             match t with
             | [Latex (code)] ->
                self#html_of_Latex b ("$" ^ (String.trim code) ^ "$")
             | _ -> ()
           end
        | "eq" ->
           begin
             match t with
             | [Latex (code)] ->
                Buffer.add_string b "<p>";
                self#html_of_Latex b ("\\[" ^ (String.trim code) ^ "\\]");
                Buffer.add_string b "</p>"
             | _ -> ()
           end
        | _ -> super#html_of_custom_text b s t
    end
  end

let _ = Odoc_args.extend_html_generator (module Ltxhtml_generator)

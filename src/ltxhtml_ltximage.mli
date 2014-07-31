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

exception Command_error of string * string (* command, message *)

type t

(** [create dir] creates a LaTeX image generator.
    @param dir a directory for LaTeX image files.
 *)
val create : string -> t

(** [generate g ~latex ~header ~footer ~dvigif ~fg ~bg ~resolution code]
    compiles LaTeX code and generates a LaTeX image.
    @return the file name of the generated LaTeX image.
    @param g a LaTeX image generator.
    @param latex LaTeX command.
    @param header the header of a LaTeX file.
    @param footer the footer of a LaTeX file.
    @param dvigif dvigif command.
    @param fg Foreground color.
    @param bg Background color.
    @param resolution the resolution of the LaTeX image.
    @param code LaTeX code.
 *)
val generate : t ->
               latex:string -> header:string -> footer:string ->
               dvigif:string -> fg:string -> bg:string -> resolution:int ->
               string -> string

(** [cleanup g] removes unused LaTeX images and a temporary directory.
    @param g a LaTeX image generator.
 *)
val cleanup : t -> unit

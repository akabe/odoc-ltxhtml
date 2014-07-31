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

exception Command_error of string * string (* command, message *)

type t =
    { image_dir : string;
      tmp_dir : string;
      digest_tbl : (Digest.t, bool) Hashtbl.t; }

let verbosef fmt = Printf.kprintf (fun s () -> verbose s) fmt

(** Run the given command on shell and return output of the command. *)
let run_cmd cmd =
  let ic = Unix.open_process_in (cmd ^ " 2>&1") in
  let msg =
    let buf = Buffer.create 256 in
    try
      while true do
        Buffer.add_string buf (input_line ic);
        Buffer.add_char buf '\n'
      done;
      assert(false)
    with End_of_file -> Buffer.contents buf
  in
  match Unix.close_process_in ic with
  | Unix.WEXITED 0 -> msg (* Success *)
  | _ -> raise (Command_error (cmd, msg)) (* Failure *)

(** Make a temporary directory. *)
let make_tmp_dir () =
  let cmd = sprintf "mktemp -d -p %s ltxhtml.XXXXXXXX"
                    (Filename.quote (Filename.get_temp_dir_name ())) in
  String.trim (run_cmd cmd)

let create dir =
  let digest_tbl = Hashtbl.create 16 in
  begin
    let dh = Unix.opendir dir in
    try
      while true do
        let filename = Unix.readdir dh in
        try
          let basename = Filename.chop_extension filename in
          Hashtbl.add digest_tbl (Digest.from_hex basename) false;
        with
        | Invalid_argument _ -> ()
      done
    with
    | End_of_file -> Unix.closedir dh
  end;
  { image_dir = dir;
    tmp_dir = make_tmp_dir ();
    digest_tbl = digest_tbl }

(** Execute `latex' command *)
let run_latex ~latex ~header ~footer dir filename code =
  let oc = open_out ((Filename.concat dir filename) ^ ".tex") in
  output_string oc (header ^ (String.trim code) ^ footer);
  close_out oc;
  let cmd = sprintf "%s -halt-on-error -interaction=nonstopmode \
                     -output-directory=%s %s"
                    latex
                    (Filename.quote dir)
                    (Filename.quote (filename ^ ".tex")) in
  ignore (run_cmd cmd)

(** Execute `dvigif' command *)
let run_dvigif ~dvigif ~fg ~bg ~resolution dir filename =
  let pathname = Filename.concat dir filename in
  let cmd = sprintf "%s -D %d -T tight -fg '%s' -bg '%s' -o %s %s"
                    dvigif resolution
                    (String.escaped fg) (String.escaped bg)
                    (Filename.quote (pathname ^ ".gif"))
                    (Filename.quote (pathname ^ ".dvi")) in
  ignore (run_cmd cmd)

let generate {digest_tbl; image_dir; tmp_dir}
             ~latex ~header ~footer ~dvigif ~fg ~bg ~resolution code =
  let digest = Digest.string code in
  let filename = Digest.to_hex digest in
  let img_path = (Filename.concat image_dir filename) ^ ".gif" in
  if Hashtbl.mem digest_tbl digest
  then
    verbosef "LaTeX image %s exists, we don't generate it." img_path ()
  else
    begin
      verbosef "Generate LaTeX image %s..." img_path ();
      run_latex ~latex ~header ~footer tmp_dir filename code;
      run_dvigif ~dvigif ~fg ~bg ~resolution tmp_dir filename;
      Unix.rename ((Filename.concat tmp_dir filename) ^ ".gif") img_path
    end;
  Hashtbl.replace digest_tbl digest true;
  filename ^ ".gif"

let cleanup {digest_tbl; image_dir; tmp_dir} =
  ignore (Unix.system ("rm -rf " ^ tmp_dir));
  let remove_if_unused digest is_used =
    if not is_used
    then
      let hex = Digest.to_hex digest in
      let filename = (Filename.concat image_dir hex) ^ ".gif" in
      verbose ("LaTeX image " ^ filename ^ " is unused, we remove it.");
      Unix.unlink filename
  in
  Hashtbl.iter remove_if_unused digest_tbl

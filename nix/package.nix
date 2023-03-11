{ pkgs
, lib
, buildPythonPackage
, fetchPypi
, pythonAtLeast

, six
, progressbar2
, pytest-runner
, pytest
, bsddb3
, requests
, gunicorn
, gevent
, greenlet

, ...
}:

let
  simplePackage = { name, version, hash ? null, sha256 ? null, extension ? "tar.gz", ... }@rest: buildPythonPackage ({
    pname = name;
    inherit version;

    src = fetchPypi ({
      pname = name;
      inherit version extension;
    } // (if hash != null then { inherit hash; } else { })
    // (if sha256 != null then { inherit sha256; } else { }));
  } // rest);

  flup6 = simplePackage {
    name = "flup6";
    version = "1.1.1";
    hash = "sha256-/QNMaGKjILn4F2oU+pTgXWfVnmE1nDTG2r0NMaJqQIQ=";

    # thread vs _thread issues
    doCheck = false;
  };
in
buildPythonPackage rec {
  name = "filetracker";
  version = "2.1.5";
  disabled = pythonAtLeast "3.9";

  src = ./..;

  doCheck = false;

  nativeCheckInputs = [
    pytest
  ];

  nativeBuildInputs = [
    pytest-runner
  ];

  propagatedBuildInputs = [
    six
    bsddb3
    flup6
    (gunicorn.overrideAttrs (old: {
      propagatedBuildInputs = old.propagatedBuildInputs ++ [ gevent ];
    }))
    gevent
    greenlet
    progressbar2
    requests
  ];

  # FIXME: Somehow make this work (make another wrapper package on top of this?)
  # makeWrapperArgs = [
  #   "--prefix"
  #   "PYTHONPATH"
  #   ":"
  #   (makePythonPath propagatedBuildInputs)
  #   # FIXME: This packages sitepackages should be included here for gunicorn to work fully
  # ];

  meta = with pkgs.lib; {
    description = "Filetracker caching file storage";
    homepage = "https://github.com/sio2project/filetracker";
    license = licenses.gpl3;
  };
}

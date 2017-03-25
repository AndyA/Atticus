"use strict";

var gulp = require("gulp");
var gutil = require("gulp-util");
var notify = require("gulp-notify");
var uglify = require("gulp-uglify");
var less = require("gulp-less");
var browserify = require("browserify");
var transform = require("vinyl-transform");
var through2 = require("through2");
var sourcemaps = require("gulp-sourcemaps");
var exorcist = require("exorcist");

var paths = {
  public: "public/"
}

gulp.task("less", function() {
  return gulp.src("webapp/app/**/*.less")
    .pipe(sourcemaps.init({
      loadMaps: true
    }))
    .pipe(less({
      style: "compressed",
      paths: [
        "webapp/lib/less",
        "node_modules/bootstrap/less"
      ]
    })
      .on("error", gutil.log))
    .pipe(sourcemaps.write('./'))
    .pipe(gulp.dest(paths.public));
});

gulp.task("reactify", function() {
  return gulp.src(["webapp/app/**/*.jsx"])
    .pipe(through2.obj(function(file, enc, next) {
      browserify(file.path, {
        debug: true,
        paths: ["webapp/lib"]
      })
        .transform("babelify", {
          presets: ["es2015", "react"]
        })
        .bundle(function(err, res) {
          if (err) {
            gutil.log(err);
            return;
          }
          file.contents = res;
          next(null, file);
        });
    }))
    .pipe(gulp.dest(paths.public));
});

gulp.task("build", ["less", "reactify"]);

gulp.task("watch", ["build"], function() {
  gulp.watch(["webapp/app/**/*.less"], ["less"]);
  gulp.watch(["webapp/app/**/*.jsx", "webapp/lib/**/*"], ["reactify"]);
});

gulp.task("default", ["build"]);

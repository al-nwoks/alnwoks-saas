const gulp = require('gulp');
const fileinclude = require('gulp-file-include');

// Clean dist directory
async function clean() {
  const { deleteAsync } = await import('del');
  return deleteAsync(['dist/**/*']);
}

// Process HTML files with file includes
function html() {
  return gulp.src(['index.html'])
    .pipe(fileinclude({
      prefix: '@@',
      basepath: '@file'
    }))
    .pipe(gulp.dest('dist'));
}

// Watch for changes
function watch() {
  gulp.watch(['index.html', 'src/html/**/*.html'], html);
}

// Export tasks
exports.clean = clean;
exports.html = html;
exports.watch = watch;
exports.default = gulp.series(clean, html);
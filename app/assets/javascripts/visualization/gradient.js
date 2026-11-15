// Add sprockets directives below:
//

// Computes grades for a given
visualization.Gradient = class Gradient {

  constructor(data, property, options) {
    if (options == null) { options = {}; }
    if (options.round == null) {       options.round = 5; }
    if (options.levelNumber == null) { options.levelNumber = 7; }

    // Default values
    if (this.round == null) {       this.round = options.round; }
    if (this.levelNumber == null) { this.levelNumber = options.levelNumber; }

    // Find min and max values
    this.grades   = [];
    if (data[0]) {
      this.maxValue = data[0][property];
      this.minValue = data[0][property];
      for (var zone of Array.from(data)) {
        if (zone[property] > this.maxValue) {
          this.maxValue = zone[property];
        }
        if (zone[property] < this.minValue) {
          this.minValue = zone[property];
        }
      }
      if (this.maxValue === this.minValue) {
        console.warn("Force max value to be different of min value");
        this.maxValue += 1;
      }
    } else {
      console.warn("Sets default min and max without data");
      this.maxValue = 10;
      this.minValue = 0;
    }
    console.log(`Exact min (${this.minValue}) and max (${this.maxValue}) computed`);

    // Simplify values
    const maxMagnitude = Math.magnitude(this.maxValue);
    const minMagnitude = Math.magnitude(this.minValue);
    let ref = minMagnitude;
    if (maxMagnitude.power > minMagnitude.power) {
      ref = maxMagnitude;
    }
    this.power = ref.power;
    let mag = ref.magnitude;
    if (mag >= 100) { mag = mag / 10; }
    this.maxValue = Math.ceil2(this.maxValue,  mag * this.round);
    this.minValue = Math.floor2(this.minValue, mag * this.round);
    this.length = this.maxValue - this.minValue;

    if (this.length > 0) {
      if ((this.levelNumber > this.length) && (this.length > 2)) {
        this.levelNumber = this.length;
      }
      console.log(`Min (${this.minValue}) and max (${this.maxValue}) computed`);

      // Compute grades
      for (let g = 1, end = this.levelNumber, asc = 1 <= end; asc ? g <= end : g >= end; asc ? g++ : g--) {
        var grade = {
          index: (g-1),
          min: this.minValue + (((g-1) * this.length) / this.levelNumber),
          max: this.minValue +  ((g    * this.length) / this.levelNumber)
        };
        grade.minLabel = Math.humanize(grade.min, this.power);
        grade.maxLabel = Math.humanize(grade.max, this.power);
        this.grades.push(grade);
      }
      console.log("Grades computed");
    }
  }

  // Returns the grade for the given value
  gradeFor(value) {
    let level = Math.round((this.levelNumber * (value - this.minValue)) / this.length);
    if (level >= this.levelNumber) { level = this.levelNumber - 1; }
    if ((level < 0) || isNaN(level)) { level = 0; }
    return this.grades[level];
  }

  // Returns if the gradient is valid
  valid() {
    return this.length > 0;
  }
};

// An Integrator represents a single value, which can be set to an initial value, and
// which then transitions to a target value over a number of steps. For example:
//
// Integrator myIntegrator(4);                            // Set an initial value
// myIntegrator.target(-2);                               // Se a target value
// myIntegrator.update();                                 // This performs the transition
// ellipse(x, y, myIntegrator.value, myIntegrator.value); // Do something with the value of the Integrator
class Integrator {

  final float DAMPING = 0.5f;
  final float ATTRACTION = 0.2f;

  float value;
  float vel;
  float accel;
  float force;
  float mass = 1;

  float damping = DAMPING;
  float attraction = ATTRACTION;
  boolean targeting;
  float target;

  // Constructor
  Integrator() { }

  // Single parameter constructor
  Integrator(float value) {
    this.value = value;
  }

  Integrator(float value, float damping, float attraction) {
    this.value = value;
    this.damping = damping;
    this.attraction = attraction;
  }

  void set(float v) {
    value = v;
  }


  void update() {
    if (targeting) {
      force += attraction * (target - value);      
    }

    accel = force / mass;
    vel = (vel + accel) * damping;
    value += vel;

    force = 0;
  }


  void target(float t) {
    targeting = true;
    target = t;
  }


  void noTarget() {
    targeting = false;
  }
}


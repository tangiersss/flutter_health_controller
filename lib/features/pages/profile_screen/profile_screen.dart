import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final TextEditingController _ageController = TextEditingController();
  final TextEditingController _weightController = TextEditingController();
  final TextEditingController _heightController = TextEditingController();
  final TextEditingController _stepsController = TextEditingController();
  final TextEditingController _bedtimeController = TextEditingController();
  final TextEditingController _wakeUpController = TextEditingController();
  String? _selectedGender;

  @override
  void dispose() {
    _ageController.dispose();
    _weightController.dispose();
    _heightController.dispose();
    _stepsController.dispose();
    _bedtimeController.dispose();
    _wakeUpController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.red.shade100,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Edit Profile",
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            _buildNumberField("Age", "Enter your age", _ageController),
            _buildGenderDropdown(),
            _buildWeightField(),
            _buildHeightField(),
            const SizedBox(height: 30),
            const Text(
              "Fitness Goals",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            _buildNumberField(
                "Steps", "Enter your daily step goal", _stepsController),
            const SizedBox(height: 30),
            const Text(
              "Sleep Schedule",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            _buildTimeField("Bedtime", "Enter your bedtime (e.g., 10:00 PM)",
                _bedtimeController),
            _buildTimeField("Wake-up",
                "Enter your wake-up time (e.g., 6:00 AM)", _wakeUpController),
            const SizedBox(height: 30),
            Center(
              child: ElevatedButton(
                onPressed: _saveProfileData,
                child: const Text("Save"),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNumberField(
      String label, String hint, TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: TextField(
        controller: controller,
        keyboardType: TextInputType.number,
        inputFormatters: [
          FilteringTextInputFormatter.digitsOnly,
        ],
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          filled: true,
          fillColor: Colors.white,
        ),
      ),
    );
  }

  Widget _buildWeightField() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: TextField(
        controller: _weightController,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        inputFormatters: [
          FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
        ],
        decoration: InputDecoration(
          labelText: "Weight",
          hintText: "Enter your weight (e.g., 70.5)",
          suffixText: _weightController.text.isNotEmpty ? "kg" : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          filled: true,
          fillColor: Colors.white,
        ),
        onChanged: (value) {
          setState(() {});
        },
      ),
    );
  }

  Widget _buildHeightField() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: TextField(
        controller: _heightController,
        keyboardType: TextInputType.number,
        inputFormatters: [
          FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
        ],
        decoration: InputDecoration(
          labelText: "Height",
          hintText: "Enter your height (e.g., 170)",
          suffixText: _heightController.text.isNotEmpty ? "cm" : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          filled: true,
          fillColor: Colors.white,
        ),
        onChanged: (value) {
          setState(() {});
        },
      ),
    );
  }

  Widget _buildTimeField(
      String label, String hint, TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: TextField(
        controller: controller,
        keyboardType: TextInputType.datetime,
        inputFormatters: [
          FilteringTextInputFormatter.allow(RegExp(r'^[0-9: ]+'))
        ],
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          filled: true,
          fillColor: Colors.white,
        ),
        onTap: () async {
          TimeOfDay? pickedTime = await showTimePicker(
            context: context,
            initialTime: TimeOfDay.now(),
          );
          if (pickedTime != null) {
            controller.text = pickedTime.format(context);
          }
        },
      ),
    );
  }

  Widget _buildGenderDropdown() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: SizedBox(
        width: 200,
        child: DropdownButtonFormField<String>(
          value: _selectedGender,
          items: const [
            DropdownMenuItem(
              value: "Male",
              child: Text("Male"),
            ),
            DropdownMenuItem(
              value: "Female",
              child: Text("Female"),
            ),
          ],
          onChanged: (value) {
            setState(() {
              _selectedGender = value;
            });
          },
          decoration: InputDecoration(
            labelText: "Gender",
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(15),
            ),
            filled: true,
            fillColor: Colors.white,
          ),
        ),
      ),
    );
  }

  void _saveProfileData() {
    String age = _ageController.text;
    String gender = _selectedGender ?? "Not selected";
    String weight = _weightController.text;
    String height = _heightController.text;
    String steps = _stepsController.text;
    String bedtime = _bedtimeController.text;
    String wakeUp = _wakeUpController.text;

    if (age.isEmpty || weight.isEmpty || height.isEmpty || steps.isEmpty) {
      _showErrorDialog("Please fill all fields!");
      return;
    }

    print("Age: $age");
    print("Gender: $gender");
    print("Weight: $weight kg");
    print("Height: $height cm");
    print("Steps: $steps");
    print("Bedtime: $bedtime");
    print("Wake-up: $wakeUp");
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Error"),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text("OK"),
          ),
        ],
      ),
    );
  }
}

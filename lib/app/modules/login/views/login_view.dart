// ignore_for_file: public_member_api_docs, sort_constructors_first

import 'package:flutter/material.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:get/get.dart';

import '../../../translations/app_translations.dart';
import '../controllers/login_controller.dart';

class LoginView extends GetView<LoginController> {
  const LoginView({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(LocaleKeys.login.tr),
        centerTitle: true,
        actions: [
          PopupMenuButton<dynamic>(
            itemBuilder: (context) => [
              PopupMenuItem(
                value: "zh_CN",
                onTap: () {
                  controller.changeLanguage(const Locale('zh', "CN"));
                  Get.updateLocale(const Locale('zh', "CN"));
                },
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text("简体"),
                    Icon(Icons.check,
                        color: LoginController.to.locale.value == const Locale('zh', "CN")
                            ? Colors.green
                            : Colors.transparent)
                  ],
                ),
              ),
              const PopupMenuDivider(),
              PopupMenuItem(
                value: "zh_HK",
                onTap: () {
                  controller.changeLanguage(const Locale('zh', "HK"));
                  Get.updateLocale(const Locale('zh', "HK"));
                },
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text("繁體"),
                    Icon(Icons.check,
                        color: LoginController.to.locale.value == const Locale('zh', "HK")
                            ? Colors.green
                            : Colors.transparent)
                  ],
                ),
              ),
              const PopupMenuDivider(),
              PopupMenuItem(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text("English"),
                    Icon(Icons.check,
                        color: LoginController.to.locale.value == const Locale('en', "US")
                            ? Colors.green
                            : Colors.transparent)
                  ],
                ),
                onTap: () {
                  controller.changeLanguage(const Locale('en', "US"));
                  Get.updateLocale(const Locale('en', "US"));
                },
              ),
            ],
            icon: const Icon(Icons.more_horiz),
            iconSize: 25,
          )
        ],
      ),
      body: SafeArea(
        child: Container(
          margin: EdgeInsets.all(Get.context!.width * 0.02),
          child: Form(
            key: LoginController.to.formKey,
            child: SingleChildScrollView(
              child: AnimationLimiter(
                child: Column(
                  children: AnimationConfiguration.toStaggeredList(
                    duration: const Duration(milliseconds: 375),
                    childAnimationBuilder: (widget) => SlideAnimation(
                      horizontalOffset: MediaQuery.of(context).size.width / 2,
                      child: FadeInAnimation(child: widget),
                    ),
                    children: [
                      //公司
                      TextInput(
                        prefixIcon: Icons.apartment,
                        inputController: LoginController.to.companyController,
                        lableText: LocaleKeys.company.tr,
                      ),
                      const SizedBox(height: 15),
                      //收银机
                      TextInput(
                        prefixIcon: Icons.price_change,
                        inputController: LoginController.to.stationController,
                        lableText: LocaleKeys.station.tr,
                        keyboardType: TextInputType.number,
                      ),
                      const SizedBox(height: 15),
                      //用戶
                      TextInput(
                        prefixIcon: Icons.person,
                        inputController: LoginController.to.userController,
                        keyboardType: TextInputType.visiblePassword,
                        lableText: LocaleKeys.user.tr,
                      ),
                      const SizedBox(height: 15),
                      //密碼
                      Obx(() {
                        return TextInput(
                          prefixIcon: Icons.verified_user,
                          inputController: LoginController.to.pwdController,
                          lableText: LocaleKeys.password.tr,
                          keyboardType: TextInputType.visiblePassword,
                          textInputAction: TextInputAction.done,
                          obscureText: !LoginController.to.visibility.value,
                          suffixIcon: LoginController.to.visibility.value ? Icons.visibility : Icons.visibility_off,
                          onTap: () => LoginController.to.visibility.value = !LoginController.to.visibility.value,
                        );
                      }),

                      const SizedBox(height: 15),
                      Obx(() {
                        return CheckboxListTile(
                          controlAffinity: ListTileControlAffinity.leading,
                          activeColor: Colors.green,
                          contentPadding: EdgeInsets.zero,
                          title: Text(
                            LocaleKeys.rememberMe.tr,
                            style: TextStyle(fontSize: 16, color: Colors.grey[700]),
                          ),
                          value: LoginController.to.isCheck.value,
                          onChanged: ((value) {
                            LoginController.to.isCheck.value = value!;
                          }),
                        );
                      }),

                      const SizedBox(height: 20),

                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          style: ButtonStyle(
                            backgroundColor: WidgetStateProperty.resolveWith((states) {
                              if (states.contains(WidgetState.pressed)) {
                                return const Color.fromARGB(66, 30, 29, 29);
                              }
                              return const Color.fromARGB(255, 59, 137, 62);
                            }),
                            foregroundColor: WidgetStateProperty.resolveWith((states) {
                              if (states.contains(WidgetState.pressed)) {
                                return Colors.white54;
                              }
                              return Colors.white;
                            }),
                            shape: WidgetStateProperty.all<RoundedRectangleBorder>(
                                RoundedRectangleBorder(borderRadius: BorderRadius.circular(30))),
                            padding: WidgetStateProperty.all(
                              const EdgeInsets.symmetric(horizontal: 60, vertical: 12),
                            ),
                          ),
                          onPressed: () {
                            FocusManager.instance.primaryFocus?.unfocus();
                            LoginController.to.login();
                          },
                          child: Text(
                            LocaleKeys.login.tr,
                            style: const TextStyle(fontSize: 18),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class TextInput extends StatelessWidget {
  final TextEditingController inputController;
  final String lableText;
  final IconData prefixIcon;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final bool obscureText;
  final IconData suffixIcon;
  final void Function()? onTap;

  const TextInput({
    super.key,
    required this.inputController,
    required this.lableText,
    required this.prefixIcon,
    this.keyboardType = TextInputType.text,
    this.textInputAction = TextInputAction.next,
    this.obscureText = false,
    this.suffixIcon = Icons.cancel,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      autovalidateMode: AutovalidateMode.onUserInteraction,
      controller: inputController,
      style: TextStyle(color: Colors.grey[900], fontSize: 18),
      decoration: InputDecoration(
        //contentPadding: const EdgeInsets.only(left: 0, right: 0, top: 16, bottom: 20),
        hintText: lableText,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Theme.of(context).colorScheme.primary, width: 2.0),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Theme.of(context).colorScheme.error, width: 2.0),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Theme.of(context).colorScheme.error, width: 2.0),
        ),
        prefixIcon: Icon(prefixIcon),
        suffixIcon: GestureDetector(
          onTap: () {
            if (onTap != null) {
              onTap!();
            } else {
              inputController.clear();
            }
          },
          child: Icon(suffixIcon, size: 20),
        ),
      ),
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      obscureText: obscureText,
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return LocaleKeys.thisFieldIsRequired.tr;
        }
        return null;
      },
    );
  }
}

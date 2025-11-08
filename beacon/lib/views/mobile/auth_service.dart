import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

ValueNotifier<AuthService> authService = ValueNotifier(AuthService());

class AuthService {
    final FirebaseAuth firebaseAuth = FirebaseAuth.instance;

    User? get currentuser => firebaseAuth.currentUser;

    Stream<User?> get authStateChanges => firebaseAuth.authStateChanges();

    Future<UserCredential> signIn({
        required String email,
        required String password,
    }) async {
        return await firebaseAuth.signInWithEmailAndPassword(email: email, password: password);
    }

    Future<UserCredential> createAccount({
        required String email,
        required String password,
    }) async {
        return await firebaseAuth.createUserWithEmailAndPassword(email: email, password: password);
    }

    Future<void> signOut() async{
        await firebaseAuth.signOut();
    }

    Future<void> resetPassword({
        required String email,
    }) async{
        await firebaseAuth.sendPasswordResetEmail(email: email);
    }

    Future<void> updateUsername({
        required String username,
    }) async {
        await currentuser!.updateDisplayName(username);
    }

    Future<void> deleteAccount({
        required String email,
        required String password,
    }) async {
        AuthCredential credential = EmailAuthProvider.credential(email: email, password: password);
        await currentuser!.reauthenticateWithCredential(credential);
        await currentuser!.delete();
        await firebaseAuth.signOut();
    }

    Future<void> updatePassword({
        required String email,
        required String password,
        required String newPassword,
    }) async
    {
        AuthCredential credential = EmailAuthProvider.credential(email: email, password: password);
        await currentuser!.reauthenticateWithCredential(credential);
        await currentuser!.updatePassword(newPassword);

    }

}



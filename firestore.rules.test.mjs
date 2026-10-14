import { readFileSync } from 'node:fs';
import { test, before, beforeEach, after } from 'node:test';
import { initializeTestEnvironment, assertSucceeds, assertFails } from '@firebase/rules-unit-testing';
import { doc, getDoc, setDoc, updateDoc, deleteDoc, collection, getDocs, serverTimestamp } from 'firebase/firestore';

const PROJECT_ID = 'demo-mindful-tcc';
const HOST = '127.0.0.1';
const PORT = 8080;
const rules = readFileSync(new URL('./firestore.rules', import.meta.url), 'utf8');
let env;
const patient = 'paciente-teste';
const other = 'outro-paciente';
const therapist = 'terapeuta-teste';
const profile = (uid, role) => ({ nome: 'Usuario Exemplo', email: `${uid}@example.test`, tipo_usuario: role, criado_em: new Date() });
const checkin = () => ({ bem_estar: 80, ansiedade: 20, cansaco: 30, sono: 70, produtividade: 60, sentimento: 'bem', criado_em: serverTimestamp() });
const assessment = (instrumento = 'GAD7', pontuacao = 10) => ({ instrumento, versao: 'demo-1', pontuacao, criado_em: serverTimestamp() });
const db = (uid) => env.authenticatedContext(uid, { email: `${uid}@example.test` }).firestore();
const anonymousDb = () => env.unauthenticatedContext().firestore();
const path = (uid, subcollection, id) => `usuarios/${uid}/${subcollection}/${id}`;

before(async () => {
  env = await initializeTestEnvironment({ projectId: PROJECT_ID, firestore: { host: HOST, port: PORT, rules } });
});
beforeEach(async () => {
  await env.clearFirestore();
  await env.withSecurityRulesDisabled(async context => {
    const admin = context.firestore();
    for (const [uid, role] of [[patient, 'paciente'], [other, 'paciente'], [therapist, 'terapeuta']]) {
      await setDoc(doc(admin, `usuarios/${uid}`), profile(uid, role));
    }
  });
});
after(async () => { if (env) await env.cleanup(); });

test('01 paciente lê seu próprio perfil', async () => {
  await assertSucceeds(getDoc(doc(db(patient), `usuarios/${patient}`)));
});
test('02 paciente não lê perfil de outra conta', async () => {
  await assertFails(getDoc(doc(db(patient), `usuarios/${other}`)));
});
test('03 usuário anônimo não lê perfil', async () => {
  await assertFails(getDoc(doc(anonymousDb(), `usuarios/${patient}`)));
});
test('04 paciente cria check-in válido', async () => {
  await assertSucceeds(setDoc(doc(db(patient), path(patient, 'checkins', 'c1')), checkin()));
});
test('05 paciente não cria check-in em outra conta', async () => {
  await assertFails(setDoc(doc(db(patient), path(other, 'checkins', 'c1')), checkin()));
});
test('06 terapeuta não lê check-ins de paciente', async () => {
  await assertFails(getDocs(collection(db(therapist), `usuarios/${patient}/checkins`)));
});
test('07 paciente cria avaliação válida', async () => {
  await assertSucceeds(setDoc(doc(db(patient), path(patient, 'avaliacoes', 'a1')), assessment()));
});
test('08 avaliação com pontuação inválida é negada', async () => {
  await assertFails(setDoc(doc(db(patient), path(patient, 'avaliacoes', 'a1')), assessment('GAD7', 22)));
});
test('09 check-in com campo extra é negado', async () => {
  await assertFails(setDoc(doc(db(patient), path(patient, 'checkins', 'c1')), { ...checkin(), respostas_json: '{}' }));
});
test('10 alteração e exclusão de registro são negadas', async () => {
  await env.withSecurityRulesDisabled(async context => {
    await setDoc(doc(context.firestore(), path(patient, 'checkins', 'c1')), { ...checkin(), criado_em: new Date() });
  });
  await assertFails(updateDoc(doc(db(patient), path(patient, 'checkins', 'c1')), { sentimento: 'outro' }));
  await assertFails(deleteDoc(doc(db(patient), path(patient, 'checkins', 'c1'))));
});
test('11 usuário não muda seu tipo de perfil', async () => {
  await assertFails(updateDoc(doc(db(patient), `usuarios/${patient}`), { tipo_usuario: 'terapeuta' }));
});
test('12 coleção não autorizada é negada', async () => {
  await assertFails(getDoc(doc(db(patient), 'segredos/documento')));
});

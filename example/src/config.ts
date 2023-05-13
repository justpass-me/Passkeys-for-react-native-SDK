import axios from 'axios';
//import {Platform} from 'react-native';

const USE_LOCAL_SERVER = false; //__DEV__ && Platform.OS === 'ios';
const BACKEND_URL = USE_LOCAL_SERVER
  ? 'http://127.0.0.1:5001/flutterdemo-f5263/us-central1/ext-justpass-me-local-oidc'
  : 'https://us-central1-flutterdemo-f5263.cloudfunctions.net/ext-justpass-me-oidc';

export const REGISTER_URL = `${BACKEND_URL}/register/`;
export const AUTHENTICATE_URL = `${BACKEND_URL}/authenticate/`;
export const passwordMinLen = 4;
export const apiClient = axios.create({
  baseURL: `${BACKEND_URL}/`,
  withCredentials: true,
});

import {defineStore} from 'pinia'
import {api} from 'boot/axios';
import {processLoadError, SESSION_ID_STORAGE_KEY} from "src/store/store_utils";

export interface EntityUserEmail {
  email: string,
  confirmed: boolean,
}

export interface EntityUserPhone {
  phone: string,
  confirmed: boolean,
}

export interface EntityUserImage {
  id: number,
  contentType: string|null,
}

export interface EntityUser {
  userId: number,
  firstName: string,
  lastName: string,
  nickName: string,
  primaryImage?: EntityUserImage,
  phones: Array<EntityUserPhone>,
  emails: Array<EntityUserEmail>,
  images: Array<EntityUserImage>,
}

const emptyUser: EntityUser = {
  userId: 0,
  firstName: '',
  lastName: '',
  nickName: '',
  phones: [],
  emails: [],
  images: [],
};

export const useStoreLogin = defineStore('login', {
  state: () => ({
    sessionId: '',
    user: {...emptyUser} as EntityUser,
    userFull: {...emptyUser} as EntityUser,
  }),

  getters: {
    isAuthenticated(state) {
      const b = state.sessionId.length > 0;
      console.log(`is authenticated: ${String(b)}`)
      return b;
    },

    fullName(state) {
      return `${state.user.firstName} ${state.user.lastName}`;
    }
  },

  actions: {
    async authenticate (sessionId?: string) {
      if (sessionId === undefined) {
        console.log('Authenticate from local storage')
        const newSessionId = localStorage.getItem(SESSION_ID_STORAGE_KEY);
        if (!newSessionId) {
          console.log('    Not found')
          return;
        }
        sessionId = newSessionId;
      } else {
        console.log(`Authenticate new ${sessionId}`)
        localStorage.setItem(SESSION_ID_STORAGE_KEY, sessionId);
      }

      this.sessionId = sessionId;

      try {
        const axiosResponse = await api.get('/login/user');
        console.log('User response', axiosResponse);
        this.user = axiosResponse.data as EntityUser;
        console.log('User received', this.user);
      } catch (e) {
        processLoadError('login.authenticate', e);
      }
    },

    async loadUserFull () {
      const user = (
        await api.get('/login/userFull')
      ).data as EntityUser;
      this.userFull = user;
    }
  },
});
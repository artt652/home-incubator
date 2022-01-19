package org.mpashka.totemftc.api;

import io.netty.handler.codec.http.HttpResponseStatus;
import io.quarkus.security.credential.Credential;
import io.quarkus.security.identity.IdentityProviderManager;
import io.quarkus.security.identity.SecurityIdentity;
import io.quarkus.security.identity.request.AuthenticationRequest;
import io.quarkus.vertx.http.runtime.security.ChallengeData;
import io.quarkus.vertx.http.runtime.security.HttpAuthenticationMechanism;
import io.quarkus.vertx.http.runtime.security.HttpCredentialTransport;
import io.smallrye.mutiny.Uni;
import io.vertx.ext.web.RoutingContext;
import org.jboss.resteasy.reactive.server.ServerRequestFilter;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import javax.inject.Inject;
import javax.inject.Singleton;
import javax.ws.rs.container.ContainerRequestContext;
import javax.ws.rs.container.ContainerRequestFilter;
import javax.ws.rs.core.HttpHeaders;
import java.security.Permission;
import java.security.Principal;
import java.util.Collections;
import java.util.Map;
import java.util.Optional;
import java.util.Set;
import java.util.stream.Collectors;

/**
 * https://quarkus.io/guides/security
 * https://quarkus.io/guides/security-customization
 * https://quarkus.io/guides/security-authorization
 * https://quarkus.io/guides/security-built-in-authentication
 */
@Singleton
public class MySecurityProvider implements HttpAuthenticationMechanism {

    private static final Logger log = LoggerFactory.getLogger(MySecurityProvider.class);

    private static final String AUTH_PREFIX = "bearer ";

    @Inject
    WebSessionService webSessionService;

    @Override
    public Uni<SecurityIdentity> authenticate(RoutingContext context, IdentityProviderManager identityProviderManager) {
        String auth = context.request().getHeader(HttpHeaders.AUTHORIZATION);
        String sessionId = MySecurityProvider.extractSessionId(auth);
        log.debug("Auth[{}]: {}, sessionId: {}", context.request().uri(), auth, sessionId);
        if (sessionId == null) {
            return Uni.createFrom().optional(Optional.empty());
        }
        return webSessionService.fetchSession(sessionId)
                .onItem().invoke(session -> log.debug("Session: {}", session))
                .onItem().transform(session -> session != null ? new MySecurityIdentity(session) : null);
    }

    @Override
    public Uni<ChallengeData> getChallenge(RoutingContext context) {
        log.info("::getChallenge");
        ChallengeData challengeData = new ChallengeData(HttpResponseStatus.FORBIDDEN.code(), null, null);
        return Uni.createFrom().item(challengeData);
    }

    @Override
    public Set<Class<? extends AuthenticationRequest>> getCredentialTypes() {
        log.info("::getCredentialTypes");
        return Collections.emptySet();
    }

    @Override
    public HttpCredentialTransport getCredentialTransport() {
        log.info("::getCredentialTransport");
        return new HttpCredentialTransport(HttpCredentialTransport.Type.AUTHORIZATION, "token");
    }

    private static String extractSessionId(String authHeader) {
        if (authHeader == null || !authHeader.toLowerCase().startsWith(MySecurityProvider.AUTH_PREFIX)) {
            return null;
        }
        String sessionId = authHeader.substring(MySecurityProvider.AUTH_PREFIX.length()).trim();
        return sessionId;
    }


    /**
     * Set session to request parameter.
     * Is needed since {@link HttpAuthenticationMechanism} doesn't have access to request context
     */
    @Singleton
    public static class MySecurityFilter implements ContainerRequestFilter {

        @Inject
        WebSessionService webSessionService;

        @ServerRequestFilter(preMatching = true)
        public void filter(ContainerRequestContext requestContext) {
            String auth = requestContext.getHeaderString(HttpHeaders.AUTHORIZATION);
            String sessionId = MySecurityProvider.extractSessionId(auth);
            log.debug("Auth[{}]: {}, sessionId: {}", requestContext.getUriInfo().getRequestUri(), auth, sessionId);
            if (sessionId == null) {
                return;
            }
            WebSessionService.Session session = webSessionService.getSession(sessionId);
            log.debug("    session: {}", session);
            if (session == null) {
                return;
            }
            webSessionService.setSession(session);
        }
    }

    private static class MySecurityIdentity implements SecurityIdentity, Principal {

        private WebSessionService.Session session;

        public MySecurityIdentity(WebSessionService.Session session) {
            this.session = session;
        }

        @Override
        public Principal getPrincipal() {
            return this;
        }

        @Override
        public String getName() {
            return session.getUser().getNickName();
        }

        @Override
        public boolean isAnonymous() {
            return false;
        }

        @Override
        public Set<String> getRoles() {
            return session.getUser().getTypes().stream().map(DbUser.UserType::name).collect(Collectors.toSet());
        }

        @Override
        public boolean hasRole(String role) {
            return session.getUser().getTypes().contains(DbUser.UserType.valueOf(role));
        }

        @Override
        public <T extends Credential> T getCredential(Class<T> credentialType) {
            return null;
        }

        @Override
        public Set<Credential> getCredentials() {
            return null;
        }

        @Override
        public <T> T getAttribute(String name) {
            return null;
        }

        @Override
        public Map<String, Object> getAttributes() {
            return null;
        }

        @Override
        public Uni<Boolean> checkPermission(Permission permission) {
            return Uni.createFrom().item(hasRole(permission.getName()));
        }
    }

}
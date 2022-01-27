package org.mpashka.totemftc.api;

import io.quarkus.security.Authenticated;
import io.smallrye.mutiny.Uni;
import org.jboss.resteasy.reactive.RestPath;
import org.jboss.resteasy.reactive.RestQuery;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import javax.annotation.security.RolesAllowed;
import javax.inject.Inject;
import javax.ws.rs.Consumes;
import javax.ws.rs.GET;
import javax.ws.rs.POST;
import javax.ws.rs.PUT;
import javax.ws.rs.Path;
import javax.ws.rs.PathParam;
import javax.ws.rs.Produces;
import javax.ws.rs.QueryParam;
import javax.ws.rs.core.MediaType;
import java.time.LocalDateTime;

/**
 */
@Path("/api/visit")
@Authenticated
public class WebResourceVisit {
    private static final Logger log = LoggerFactory.getLogger(WebResourceVisit.class);

    @Inject
    DbCrudVisit dbVisit;

    @Inject
    WebSessionService webSessionService;

    @GET
    @Path("byCurrentUser")
    @Produces(MediaType.APPLICATION_JSON)
    public Uni<DbCrudVisit.EntityVisit[]> listByCurrentUser(@QueryParam("from") LocalDateTime from) {
        return dbVisit.getByUser(webSessionService.getUserId(), from);
    }

    @GET
    @Path("byUser/{userId}")
    @Produces(MediaType.APPLICATION_JSON)
    @RolesAllowed({MySecurityProvider.ROLE_TRAINER, MySecurityProvider.ROLE_ADMIN})
    public Uni<DbCrudVisit.EntityVisit[]> listByUser(@RestPath int userId, @RestQuery LocalDateTime from) {
        return dbVisit.getByUser(userId, from);
    }

    @GET
    @Path("byTicket/{ticketId}")
    @Produces(MediaType.APPLICATION_JSON)
    @RolesAllowed({MySecurityProvider.ROLE_TRAINER, MySecurityProvider.ROLE_ADMIN})
    public Uni<DbCrudVisit.EntityVisit[]> listByTicket(@PathParam("ticketId") int ticketId) {
        return dbVisit.getByTicket(ticketId);
    }

    @GET
    @Path("byTraining/{trainingId}")
    @Produces(MediaType.APPLICATION_JSON)
    @RolesAllowed({MySecurityProvider.ROLE_TRAINER, MySecurityProvider.ROLE_ADMIN})
    public Uni<DbCrudVisit.EntityVisit[]> listByTraining(@PathParam("trainingId") int trainingId) {
        return dbVisit.getByTraining(trainingId);
    }

    @PUT
    @Path("delete")
    @RolesAllowed(MySecurityProvider.ROLE_ADMIN)
    public Uni<DbCrudTicket.EntityTicket> delete(DbCrudVisit.EntityVisit visit) {
        return dbVisit.delete(visit);
    }

    @POST
    @Consumes(MediaType.APPLICATION_JSON)
    @RolesAllowed(MySecurityProvider.ROLE_ADMIN)
    public Uni<DbCrudTicket.EntityTicket> create(DbCrudVisit.EntityVisit visit) {
        return dbVisit.updateMark(visit, null, null, null);
    }

    @PUT
    @Consumes(MediaType.APPLICATION_JSON)
    public Uni<Void> updateComment(DbCrudVisit.EntityVisit visit) {
        return dbVisit.updateComment(visit);
    }

    @PUT
    @Path("/markSchedule/{markSchedule}")
    @Consumes(MediaType.APPLICATION_JSON)
    public Uni<DbCrudTicket.EntityTicket> updateMarkSchedule(DbCrudVisit.EntityVisit visit, @PathParam("markSchedule") boolean markSchedule) {
        return dbVisit.updateMark(visit, markSchedule, null, null);
    }

    @PUT
    @Path("/markSelf/{markSelf}")
    @Consumes(MediaType.APPLICATION_JSON)
    public Uni<DbCrudTicket.EntityTicket> updateMarkSelf(DbCrudVisit.EntityVisit visit, @PathParam("markSelf") DbCrudVisit.EntityVisitMark markSelf) {
        return dbVisit.updateMark(visit, null, markSelf, null);
    }

    @PUT
    @Path("/markMaster/{markMaster}")
    @Consumes(MediaType.APPLICATION_JSON)
    @RolesAllowed({MySecurityProvider.ROLE_TRAINER, MySecurityProvider.ROLE_ADMIN})
    public Uni<DbCrudTicket.EntityTicket> updateMarkMaster(DbCrudVisit.EntityVisit visit, @PathParam("markMaster") DbCrudVisit.EntityVisitMark markMaster) {
        // todo [!] trainer can mark only own
        return dbVisit.updateMark(visit, null, null, markMaster);
    }
}
